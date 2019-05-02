function run-tracked() {
  local opt ret opts1 aliases1 bindings1 traps1 opts2 aliases2 bindings2 traps2 finished

  {
    local -A flags
    while getopts "toabv" opt; do
      case $opt in
        '?') return 1;;
        +*) flags[${opt:1}]=+;;
        *) flags[$opt]=-;;
      esac
    done

    local -a cmd=("${(@)*:$OPTIND}")

    opts1=$(setopt)                                        || return
    aliases1=$(alias -rL; alias -gL; alias -sL)            || return
    bindings1=$(bindkey -L)                                || return
    traps1=$(mktemp "${TMPDIR:-/tmp}"/traps1.XXXXXXXXXX)   || return
    trap >$traps1                                          || return

    "${(@)cmd}"
    ret=$?

    if [[ $flags[o] == - ]]; then
      emulate zsh                                          || return
      setopt -- ${(@f)opts1}                               || return
    elif [[ $flags[o] != '+' && $flags[v] == '-' ]]; then
      opts2=$(setopt)                                      || return
      if [[ $opts1 != $opts2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: options changed by: ${(@q-)cmd}${(%):-%f}" >&2
        diff <(echo -E $opts1) <(echo -E $opts2) | awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[a] == - ]]; then
      unalias -m \*                                        || return
      eval "$aliases1"                                     || return
    elif [[ $flags[a] != '+' && $flags[v] == '-' ]]; then
      aliases2=$(alias -rL; alias -gL; alias -sL)          || return
      if [[ $aliases1 != $aliases2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: aliases changed by: ${(@q-)cmd}${(%):-%f}" >&2
        diff <(echo -E $aliases1) <(echo -E $aliases2) | awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[b] == - ]]; then
      bindkey -d                                           || return
      eval "$bindings1"                                    || return
    elif [[ $flags[b] != '+' && $flags[v] == '-' ]]; then
      bindings2=$(bindkey -L)                              || return
      if [[ $bindings1 != $bindings2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: bindings changed by: ${(@q-)cmd}${(%):-%f}" >&2
        diff <(echo -E $bindings1) <(echo -E $bindings2) | awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[t] == - ]]; then
      trap -                                               || return
      eval $(<$traps1)                                     || return
    elif [[ $flags[t] != '+' && $flags[v] == '-' ]]; then
      traps2=$(mktemp "${TMPDIR:-/tmp}"/traps2.XXXXXXXXXX) || return
      trap >$traps2                                        || return
      if ! diff -q $traps1 $traps2 &>/dev/null; then
        echo -E "${(%):-%F{red\}}[WARNING]: traps changed by: ${(@q-)cmd}${(%):-%f}" >&2
        diff $traps1 $traps2 | awk '{print "  " $0}'
      fi
    fi

    finished=1
    return $ret
  } always {
    if (( ! finished )); then
      echo -E "${(%):-%F{red\}}[WARNING]: run-tracked internal error: ${(@q-)*}${(%):-%f}" >&2
    fi
    [[ -z $traps1 ]] || rm -f $traps1
    [[ -z $traps2 ]] || rm -f $traps2
  }
}

if (( WSL )); then
  # Prints Windows environment variable $1.
  function win_env() {
    emulate -L zsh
    echo -E ${$(/mnt/c/Windows/System32/cmd.exe /c "echo %$1%")%$'\r'}
  }
else
  function xopen() {
    emulate -L zsh
    xdg-open "$@" &>/dev/null &!
  }
fi
