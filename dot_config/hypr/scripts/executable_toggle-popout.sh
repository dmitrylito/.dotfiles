#!/bin/bash
# Toggle the active window between a centered 16:10 floating "pop-out" and its
# tiled spot. Pop-out size adapts to the window's monitor. On return, the whole
# workspace is nudged back to the arrangement it had at pop-out time (dwindle
# otherwise re-inserts the window swapped or in a different quadrant).
# Bound to SUPER+U.

# Tunables
MAX_W_FRAC=0.80   # up to 80% of monitor width
MAX_H_FRAC=0.82   # up to 82% of monitor height
RATIO=1.6         # 16:10
THRESH=100        # px (manhattan): a window closer than this counts as "in place"
MAXIT=8           # max correction passes

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/hypr-popout"
mkdir -p "$STATE_DIR"

WIN=$(hyprctl activewindow -j)
ADDR=$(echo "$WIN" | jq -r '.address // empty')
[ -z "$ADDR" ] && exit 0
FLOAT=$(echo "$WIN" | jq -r '.floating')
STATE="$STATE_DIR/$ADDR"

# center of a window: "cx cy" (floor). Args: <clients-json> <address>
center_of() { echo "$1" | jq -r --arg a "$2" \
  '.[]|select(.address==$a)|"\((.at[0]+.size[0]/2)|floor) \((.at[1]+.size[1]/2)|floor)"'; }

if [ "$FLOAT" = "true" ]; then
  # ---------- Return to tiling ----------
  hyprctl dispatch togglefloating
  [ -f "$STATE" ] || exit 0
  SNAP=$(cat "$STATE"); rm -f "$STATE"          # entries: addr:cx:cy addr:cx:cy ...
  [ -z "$SNAP" ] && exit 0

  WS=$(hyprctl activewindow -j | jq -r '.workspace.id')
  # Only attempt restoration if the tiled window set is unchanged since pop-out.
  CUR=$(hyprctl clients -j | jq --argjson ws "$WS" \
    '[.[]|select(.workspace.id==$ws and .floating==false)]|length')
  SNAPCOUNT=$(echo "$SNAP" | wc -w)
  if [ "$CUR" != "$SNAPCOUNT" ]; then
    exit 0    # windows opened/closed while popped out -> slot may be gone, leave as-is
  fi

  prev_total=""
  for _ in $(seq 1 "$MAXIT"); do
    CLIENTS=$(hyprctl clients -j)
    total=0; worst_addr=""; worst_d=-1; worst_dx=0; worst_dy=0
    for entry in $SNAP; do
      addr=${entry%%:*}; rest=${entry#*:}; tx=${rest%%:*}; ty=${rest#*:}
      read -r cx cy < <(center_of "$CLIENTS" "$addr")
      [ -z "$cx" ] && continue
      dx=$((tx - cx)); dy=$((ty - cy)); adx=${dx#-}; ady=${dy#-}
      d=$((adx + ady)); total=$((total + d))
      if [ "$d" -gt "$worst_d" ]; then
        worst_d=$d; worst_addr=$addr; worst_dx=$dx; worst_dy=$dy
      fi
    done
    # Converged: even the most-displaced window is close enough
    [ "$worst_d" -le "$THRESH" ] && break
    # Progress guard: bail if a pass stopped reducing total displacement
    [ -n "$prev_total" ] && [ "$total" -ge "$prev_total" ] && break
    prev_total=$total
    # Fix the most-displaced window with one swap toward its saved slot
    hyprctl dispatch focuswindow "address:$worst_addr" >/dev/null
    wadx=${worst_dx#-}; wady=${worst_dy#-}
    if [ "$wadx" -ge "$wady" ]; then
      [ "$worst_dx" -lt 0 ] && hyprctl dispatch swapwindow l || hyprctl dispatch swapwindow r
    else
      [ "$worst_dy" -lt 0 ] && hyprctl dispatch swapwindow u || hyprctl dispatch swapwindow d
    fi
  done
  hyprctl dispatch focuswindow "address:$ADDR" >/dev/null

else
  # ---------- Pop out: snapshot the whole workspace, then float+size+center ----------
  WS=$(echo "$WIN" | jq -r '.workspace.id')
  hyprctl clients -j | jq -r --argjson ws "$WS" \
    '[.[]|select(.workspace.id==$ws and .floating==false)]
     | map("\(.address):\((.at[0]+.size[0]/2)|floor):\((.at[1]+.size[1]/2)|floor)")
     | join(" ")' > "$STATE"

  MON=$(echo "$WIN" | jq '.monitor')
  read -r MW MH < <(hyprctl monitors -j | jq -r --argjson m "$MON" \
    '.[] | select(.id == $m) | "\(.width / .scale) \(.height / .scale)"')
  read -r POPW POPH < <(awk -v w="$MW" -v h="$MH" -v wf="$MAX_W_FRAC" \
    -v hf="$MAX_H_FRAC" -v r="$RATIO" 'BEGIN{
      maxw = w*wf; maxh = h*hf; pw = maxw; ph = pw/r;
      if (ph > maxh) { ph = maxh; pw = ph*r; }
      printf "%d %d", pw, ph;
    }')
  [ -z "$POPW" ] && { POPW=2800; POPH=1750; }

  hyprctl --batch "dispatch togglefloating ; dispatch resizeactive exact $POPW $POPH ; dispatch centerwindow"
fi
