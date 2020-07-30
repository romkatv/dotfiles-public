# Starts ssh-agent if it isn't already running.
() {
  emulate -L zsh -o no_unset -o extended_glob

  function _ssh-agent-running() {
    [[ -v SSH_AUTH_SOCK && -r $SSH_AUTH_SOCK && -w $SSH_AUTH_SOCK &&
       -v SSH_AGENT_PID && "$(command ps -p $SSH_AGENT_PID -o comm= 2>/dev/null)" == ssh-agent ]]
  }

  {
    _ssh-agent-running && return

    local env_file=${XDG_CACHE_HOME:-$HOME/.cache}/ssh-agent-env
    if [[ ! -d ${env_file:h} ]]; then
      command mkdir -pm 0700 -- ${env_file:h} || return
    fi

    if [[ -n $env_file(#qNW) || -n ${env_file:h}/(../)#(#qNW) ]]; then
      local f=$env_file
      while true; do
        if [[ -n $f(#qNW) ]]; then
          f=${(q)f//\%/%%}
          print -ru2 -- ${(%):-"Not using ssh-agent because %U$f%u is %F{1}world-writable%f."}
          print -ru2 -- ""
          print -ru2 -- "Run the following command to fix this issue:"
          print -ru2 -- ""
          print -ru2 -- ${(%):-"  %F{2}%Usudo%u chmod%f o-w -- %U$f%u"}
          return 1 
        fi
        [[ $f == / ]] && break
        f=${f:h}
      done
    fi

    if [[ -e $env_file ]]; then
      builtin source $env_file >/dev/null
      _ssh-agent-running && return
    fi

    unset SSH_AGENT_PID SSH_AUTH_SOCK
    command ssh-agent -st 20h >$env_file || return
    builtin source $env_file >/dev/null  || return
  } always {
    unfunction _ssh-agent-running
  }
}
