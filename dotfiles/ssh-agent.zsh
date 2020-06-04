# Starts ssh-agent if it isn't already running.
() {
  emulate -L zsh -o no_unset -o extended_glob

  function _ssh-agent-running() {
    [[ -v SSH_AUTH_SOCK && -r $SSH_AUTH_SOCK && -w $SSH_AUTH_SOCK &&
       -v SSH_AGENT_PID && "$(ps -p $SSH_AGENT_PID -o comm= 2>/dev/null)" == ssh-agent ]]
  }

  {
    _ssh-agent-running && return

    local env_file=${XDG_CACHE_HOME:-$HOME/.cache}/ssh-agent-env
    if [[ -d ${env_file:h} ]]; then
      command mkdir -pm 0700 -- ${env_file:h} || return
    fi

    local f=$env_file
    while true; do
      if [[ -n $f(#qNW) ]]; then
        echo "Not using ssh-agent because ${(qqq)f} is world-writable." >&2
        return 1 
      fi
      [[ $f == / ]] && break
      f=${f:h}
    done

    if [[ -e $env_file ]]; then
      source $env_file >/dev/null
      _ssh-agent-running && return
    fi

    unset SSH_AGENT_PID SSH_AUTH_SOCK
    command ssh-agent -st 20h >$env_file || return
    source $env_file >/dev/null          || return
  } always {
    unfunction _ssh-agent-running
  }
}
