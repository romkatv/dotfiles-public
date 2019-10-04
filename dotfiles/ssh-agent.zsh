# Starts ssh-agent if it isn't already running.
() {
  emulate -L zsh
  setopt err_return no_unset extended_glob

  function _ssh-agent-running() {
    unsetopt err_return
    [[ -v SSH_AUTH_SOCK && -r $SSH_AUTH_SOCK && -w $SSH_AUTH_SOCK &&
       -v SSH_AGENT_PID && "$(ps -p $SSH_AGENT_PID -o comm= 2>/dev/null)" == ssh-agent ]]
  }
  trap 'unfunction _ssh-agent-running' EXIT

  ! _ssh-agent-running || return 0

  local env_file=${XDG_CACHE_HOME:-$HOME/.cache}/ssh-agent-env
  mkdir -pm 0700 ${env_file:h}

  local f=$env_file
  while true; do
    [[ -z $f(#qNW) ]] || {
      echo "Not using ssh-agent because ${(qqq)f} is world-writable." >&2
      return 1 
    }
    [[ $f != / ]] || break
    f=${f:h}
  done

  [[ ! -e $env_file ]] || source $env_file >/dev/null
  ! _ssh-agent-running || return 0

  unset SSH_AGENT_PID SSH_AUTH_SOCK
  ssh-agent -st 20h >$env_file
  source $env_file >/dev/null
}
