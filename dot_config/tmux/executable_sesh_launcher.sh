#!/bin/bash

# Use absolute paths to ensure reliability in tmux background shells
SESH_BIN="sesh"
TMUXIFIER_BIN="$HOME/.tmuxifier/bin/tmuxifier"

# Colors for the header (ANSI escape sequences)
BLUE=$'\E[0;34m'
MAGENTA=$'\E[0;35m'
CYAN=$'\E[0;36m'
BOLD=$'\E[1m'
RESET=$'\E[0m'

# Line 1: Icons and Labels
LINE1="  ${CYAN} All${RESET}    ${BLUE} Tmux${RESET}    ${MAGENTA} Configs${RESET}    ${CYAN} Zoxide${RESET}    ${BLUE} Find${RESET}    ${BOLD}📐Layouts${RESET}    ${MAGENTA} Kill${RESET}"
# Line 2: Ctrl + Keybinds
LINE2=" Ctrl+a    Ctrl+t     Ctrl+g      Ctrl+x     Ctrl+f     Ctrl+l      Ctrl+d"

# Combine into a 2-line header
HEADER_STR="$LINE1"$'\n'"$LINE2"

# Function to list layouts with icons (uses ultra-fast native file search instead of heavy tmuxifier CLI)
list_layouts() {
  find "$HOME/.tmuxifier/layouts" -type f -name "*.sh" 2>/dev/null | sed -E 's/.+\/(.+)\.(window|session|pane)\.sh/📐 \1/'
}

# Function to list everything for the default view
list_all() {
  $SESH_BIN list -t -c --icons
  list_layouts
  $SESH_BIN list -z --icons | head -n 7
}

# Fast inline command for listing layouts in FZF subshells
FAST_LAYOUT_CMD="find \$HOME/.tmuxifier/layouts -type f -name '*.sh' 2>/dev/null | sed -E 's/.+\\/(.+)\\.(window|session|pane)\\.sh/📐 \\1/'"

# Run fzf
selected=$(list_all | fzf \
  --no-sort --ansi \
  --border-label "   sesh " \
  --prompt "⚡  " \
  --header "$HEADER_STR" \
  --bind "tab:down,btab:up" \
  --bind "ctrl-a:change-prompt(⚡  )+reload(($SESH_BIN list -t -c --icons && eval \"$FAST_LAYOUT_CMD\" && $SESH_BIN list -z --icons | head -n 7))" \
  --bind "ctrl-t:change-prompt(🪟  )+reload($SESH_BIN list -t --icons)" \
  --bind "ctrl-g:change-prompt(⚙️  )+reload($SESH_BIN list -c --icons)" \
  --bind "ctrl-x:change-prompt(📁  )+reload($SESH_BIN list -z --icons | head -n 7)" \
  --bind "ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)" \
  --bind "ctrl-l:change-prompt(📐  )+reload(eval \"$FAST_LAYOUT_CMD\")" \
  --bind "ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload($SESH_BIN list --icons)" \
  --preview-window "right:55%" \
  --preview "[[ {} == 📐* ]] && echo 'Tmuxifier Layout' || $SESH_BIN preview {}")

# Exit if nothing selected
[[ -z "$selected" ]] && exit 0

# Handle the selection
if [[ "$selected" == 📐* ]]; then
  target=$(echo "$selected" | sed 's/^📐 //')
  $TMUXIFIER_BIN load-window "$target"
else
  $SESH_BIN connect "$selected"
fi
