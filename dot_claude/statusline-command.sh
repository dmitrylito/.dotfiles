#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // empty')
# Drop the trailing context-window note, e.g. "Claude Opus 4.8 (1M context)" -> "Claude Opus 4.8"
model="${model%% (*}"
effort=$(echo "$input" | jq -r '.effort.level // empty')
[ -n "$effort" ] && model="$model · $effort"
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
[ -n "$ctx_used" ] && model="$model ($(printf '%.0f' "$ctx_used")%)"
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Current working directory — just the base name (e.g. "chezmoi")
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -n "$cwd" ] && cwd="${cwd##*/}"

# Format a resets_at value (unix epoch or ISO 8601) with the given date format;
# prints nothing if the timestamp can't be parsed.
fmt_reset() {
  local ts=$1 fmt=$2 out
  case "$ts" in
    '')         return ;;
    *[!0-9]*)   out=$(date -d "$ts" "$fmt" 2>/dev/null) ;;
    *)          out=$(date -d "@$ts" "$fmt" 2>/dev/null) ;;
  esac
  [ -n "$out" ] && printf '%s' "${out# }"
}

# Build left side: cwd, then the 5-hour and 7-day rate limits, all joined with " | "
left=""
[ -n "$cwd" ] && left="$cwd"
if [ -n "$five" ]; then
  five_part="5h: $(printf '%.0f' "$five")%"
  reset_str=$(fmt_reset "$five_reset" +%-l:%M%p)
  [ -n "$reset_str" ] && five_part="$five_part (resets $reset_str)"
  [ -n "$left" ] && left="$left | $five_part" || left="$five_part"
fi
if [ -n "$week" ]; then
  week_part="7d: $(printf '%.0f' "$week")%"
  reset_str=$(fmt_reset "$week_reset" '+%a %-l:%M%p')
  [ -n "$reset_str" ] && week_part="$week_part (resets $reset_str)"
  [ -n "$left" ] && left="$left | $week_part" || left="$week_part"
fi

# If there is nothing to show at all, exit silently
[ -z "$left" ] && [ -z "$model" ] && exit 0

# Right-align the model string using terminal width.
# Priority: COLUMNS env var, then the live tmux pane width, then 80.
# An overestimated width makes the padded line wrap inside the pane, which
# forces Claude Code to reflow the status area on every refresh (visible as
# constant flicker in split panes) — so prefer measured values and a small
# fallback over a large guess.
width="${COLUMNS:-}"
if [ -z "$width" ] && [ -n "$TMUX" ]; then
  # -t TMUX_PANE: without it tmux reports the client's active pane, which can
  # be a different (wider) pane than the one Claude Code is running in.
  width=$(tmux display-message -p ${TMUX_PANE:+-t "$TMUX_PANE"} '#{pane_width}' 2>/dev/null)
fi
width="${width:-80}"
margin=3
width=$(( width - margin ))

if [ -n "$model" ] && [ -n "$left" ]; then
  left_len=${#left}
  model_len=${#model}
  pad=$(( width - left_len - model_len ))
  [ "$pad" -lt 1 ] && pad=1
  printf '%s%*s%s' "$left" "$pad" "" "$model"
elif [ -n "$model" ]; then
  printf '%s' "$model"
else
  printf '%s' "$left"
fi
