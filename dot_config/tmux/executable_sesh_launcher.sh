#!/bin/bash

# Use absolute paths to ensure reliability in tmux background shells
SESH_BIN="/usr/bin/sesh"
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

# Function to list layouts with icons
list_layouts() {
  $TMUXIFIER_BIN lw 2>/dev/null | while read -r line; do
    echo "📐 $line"
  done
}

# Function to list everything for the default view
list_all() {
  list_layouts
  $SESH_BIN list --icons
}

# Run fzf-tmux
selected=$(list_all | fzf-tmux -p 80%,70% \
  --no-sort --ansi \
  --border-label "   sesh " \
  --prompt "⚡  " \
  --header "$HEADER_STR" \
  --bind "tab:down,btab:up" \
  --bind "ctrl-a:change-prompt(⚡  )+reload(($SESH_BIN list --icons && $TMUXIFIER_BIN lw | sed 's/^/📐 /'))" \
  --bind "ctrl-t:change-prompt(🪟  )+reload($SESH_BIN list -t --icons)" \
  --bind "ctrl-g:change-prompt(⚙️  )+reload($SESH_BIN list -c --icons)" \
  --bind "ctrl-x:change-prompt(📁  )+reload($SESH_BIN list -z --icons)" \
  --bind "ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)" \
  --bind "ctrl-l:change-prompt(📐  )+reload($TMUXIFIER_BIN lw | sed 's/^/📐 /')" \
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
