#!/usr/bin/env bash
# Pick a URL out of a tmux pane's scrollback and open it in the default browser.
# Usage: url_picker.sh [pane-id]   — bound to `prefix + u` in tmux.conf via
#   display-popup -E, so stdout belongs to the fzf UI (don't print anything else).
# Requires: fzf, xdg-open, and $TMUX (it queries the calling server).

set -uo pipefail

# display-popup is not documented to format-expand its shell-command, so the
# pane id may arrive literally as "#{pane_id}"; fall back to tmux's active pane.
pane="${1:-}"
[[ $pane == %[0-9]* ]] || pane=""

capture=(tmux capture-pane -p -J -S -5000)
[[ -n $pane ]] && capture+=(-t "$pane")

# -J unwraps rows, so a URL that tmux hard-wrapped at the pane width comes back
# in one piece — the case ctrl+click can never recover.
urls=$(
	"${capture[@]}" |
		grep -oE '(https?|ftp|file)://[^[:space:]"'\''`<>)]+' |
		sed 's/[.,;:!?]*$//' |
		tac |
		awk '!seen[$0]++'
)

if [[ -z $urls ]]; then
	tmux display-message "no URLs in this pane's scrollback"
	exit 0
fi

url=$(printf '%s\n' "$urls" | fzf --no-sort --prompt='open> ') || exit 0
[[ -n $url ]] && setsid -f xdg-open "$url" >/dev/null 2>&1
