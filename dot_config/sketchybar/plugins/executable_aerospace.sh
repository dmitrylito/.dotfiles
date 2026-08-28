#!/usr/bin/env bash
# Repaints all ten workspace pills in one sketchybar call. Invoked by the
# spaces_watcher item, not per-pill, so a workspace switch forks `aerospace`
# twice rather than twenty times.
# Empty and unfocused workspaces are hidden; the focused one is a filled pill.

source "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
OCCUPIED="$(aerospace list-workspaces --monitor all --empty no)"

args=()
for sid in 1 2 3 4 5 6 7 8 9 10; do
  if [ "$sid" = "$FOCUSED" ]; then
    args+=(--set space."$sid" drawing=on background.drawing=on \
           background.color="$BLUE" icon.color=0xff1e1e2e)
  elif printf '%s\n' "$OCCUPIED" | grep -qx "$sid"; then
    args+=(--set space."$sid" drawing=on background.drawing=on \
           background.color="$SURFACE0" icon.color="$TEXT")
  else
    args+=(--set space."$sid" drawing=off)
  fi
done

sketchybar "${args[@]}"
