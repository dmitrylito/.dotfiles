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
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Current working directory — just the base name (e.g. "chezmoi")
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -n "$cwd" ] && cwd="${cwd##*/}"

# Build left side: cwd, then Day and Week, all joined with " | "
left=""
[ -n "$cwd" ] && left="$cwd"
[ -n "$five" ] && { [ -n "$left" ] && left="$left | Day: $(printf '%.0f' "$five")%" || left="Day: $(printf '%.0f' "$five")%"; }
if [ -n "$week" ]; then
  week_part="Week: $(printf '%.0f' "$week")%"
  [ -n "$left" ] && left="$left | $week_part" || left="$week_part"
fi

# If there is nothing to show at all, exit silently
[ -z "$left" ] && [ -z "$model" ] && exit 0

# Right-align the model string using terminal width.
# Priority: COLUMNS env var, then fall back to 120.
# Leave a small right-edge margin so the status line area (slightly narrower
# than the full terminal) doesn't clip the end of the model name.
width="${COLUMNS:-120}"
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
