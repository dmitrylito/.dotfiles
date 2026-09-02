# Carapace needs compdef, so load it after Oh My Zsh. Environment variables must
# be set before the generated initialization snippet is sourced.
if (( ${+commands[carapace]} )); then
  export CARAPACE_BRIDGES='zsh,bash'
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  source <(carapace _carapace)
fi
