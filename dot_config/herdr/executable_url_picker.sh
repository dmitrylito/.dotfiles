#!/usr/bin/env bash
# Pick a URL out of a herdr pane's scrollback and open it in the default browser.
# Bound to `prefix+u` in herdr's config.toml as a popup command; herdr sets
# HERDR_ACTIVE_PANE_ID for the pane the popup was opened from. Stdout belongs
# to the fzf UI — don't print anything else.
# Requires: herdr, fzf, xdg-open.

set -uo pipefail

pane="${HERDR_ACTIVE_PANE_ID:-}"
if [[ -z $pane ]]; then
	echo "no active pane" >&2
	read -rsn1
	exit 1
fi

# recent-unwrapped rejoins rows herdr hard-wrapped at the pane width, so a
# long URL comes back in one piece — same job as tmux capture-pane -J.
urls=$(
	herdr pane read "$pane" --source recent-unwrapped --lines 5000 |
		grep -oE '(https?|ftp|file)://[^[:space:]"'\''`<>)]+' |
		sed 's/[.,;:!?]*$//' |
		tac |
		awk '!seen[$0]++'
)

if [[ -z $urls ]]; then
	echo "no URLs in this pane's scrollback — any key to close"
	read -rsn1
	exit 0
fi

url=$(printf '%s\n' "$urls" | fzf --no-sort --prompt='open> ') || exit 0
[[ -n $url ]] && setsid -f xdg-open "$url" >/dev/null 2>&1
