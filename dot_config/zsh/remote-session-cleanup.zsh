# Restore terminal modes after ssh/mosh-style commands. A dropped remote session
# can otherwise leave mouse reporting, bracketed paste, or the alt screen enabled.
_remote_session_ran=0
_remote_session_tty=''

_remote_session_preexec() {
  local -a words=(${(z)1})
  _remote_session_ran=0
  case $words[1] in
    ssh|autossh|mosh|et) _remote_session_ran=1 ;;
    tailscale) [[ $words[2] == ssh ]] && _remote_session_ran=1 ;;
  esac
  (( _remote_session_ran )) && _remote_session_tty=$(stty -g 2>/dev/null)
}

_remote_session_precmd() {
  (( _remote_session_ran )) || return
  _remote_session_ran=0
  [[ -t 0 && -t 1 ]] || return

  if [[ -n $_remote_session_tty ]]; then
    stty "$_remote_session_tty" 2>/dev/null || stty sane 2>/dev/null
  else
    stty sane 2>/dev/null
  fi
  printf '\e[?1049l\e[?1000l\e[?1002l\e[?1003l\e[?1005l\e[?1006l\e[?1015l\e[?2004l\e[?1l\e>\e[?7h\e[?25h\e[0m'
  while read -r -s -k 1 -t 0 _ 2>/dev/null; do :; done
}

add-zsh-hook preexec _remote_session_preexec
add-zsh-hook precmd _remote_session_precmd
