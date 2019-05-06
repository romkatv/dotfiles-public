# Usage: run-tracked [-w|+w] [-f|+f] [-o|+o] [-a|+a] [-b|+b] [-t|+t] cmd...
#
# Runs `cmd...` and takes action when it detects changes in the global environment.
#
# Types of environment that run-tracked can monitor:
#
#   TYPE  DESCRIPTION
#      w  zle widgets
#      f  functions
#      o  options
#      a  aliases
#      b  bindings
#      t  traps
#
# For every type of environment the default action on detected changes is to issue a warning.
# Flag -<TYPE> causes changes to be reverted. Flag +<TYPE> causes changes to be accepted without
# a warning.
#
# For zle widgets and functions, new entities are not considered changes. For all other
# environments they are.
#
# The most common use case is `run-tracked source /path/to/third-part/plugin.zsh`. There are
# plenty of plugins out there that contain something useful (e.g., a function definition) but
# it comes bundles with unwanted crap (like aliases and key bindings).
#
# Example:
#
#   function f() { echo hello }
#
#   function untrusted() {
#     bindkey '^R' redo
#     function f() { echo bye }
#   }
#
#   run-tracked untrusted  # usually this is `run-tracked source untrusted.plugin.zsh`
#
# Output:
#
#   [WARNING]: function 'f' changed by: untrusted
#     1c1
#     < 	echo hello
#     ---
#     > 	echo bye
#   [WARNING]: bindings changed by: untrusted
#     18c18
#     < bindkey "^R" history-incremental-search-backward
#     ---
#     > bindkey "^R" redo
#
# Apart from these warnings, the effect of `run-tracked untrusted` is the same as of `untrusted`.
#
# Suppose we want to accept the changes in bindings but not the override of `f`.
#
#   run-tracked +b -f untrusted
#
# There is no output. Calling `f` will print `hello`. Pressing '^R' will invoke `redo` widget.
function run-tracked() {
  local -i finished=0
  local traps1 traps2

  {
    local opt
    local -A flags
    while getopts "wfoabt" opt; do
      case $opt in
        '?') return 1;;
        +*) flags[${opt:1}]=+;;
        *) flags[$opt]=-;;
      esac
    done

    local -a cmd=("${(@)*:$OPTIND}")

    local -A widgets1=(${(kv)widgets})
    local -A functions1=(${(kv)functions})
    local -A opts1 && opts1=$(setopt)                               || return
    local aliases1 && aliases1=$(alias -rL; alias -gL; alias -sL)   || return
    local bindings1 && bindings1=$(bindkey -L)                      || return
    traps1=$(mktemp "${TMPDIR:-/tmp}"/traps1.XXXXXXXXXX)            || return
    trap >$traps1                                                   || return

    "${(@)cmd}"
    local ret=$?

    local k v

    if [[ $flags[w] == - ]]; then
      for k v in ${(kv)widgets1}; do
        case $v in
          user:*) zle -N $k ${v#*:}                                 || return;;
          completion:*) zle -C $k ${${(s.:.)v}[2,3]}                || return;;
          builtin) [[ $k == .* ]] || zle -A .$k $k                  || return;;
        esac
      done
    elif [[ $flags[w] != '+' ]]; then
      for k v in ${(kv)widgets1}; do
        if [[ $v == (user:*|completion:*|builtin) && $v != ${widgets[$k]:-} ]]; then
          echo -E "${(%):-%F{red\}}[WARNING]: widget '$k' changed by: ${(@q-)cmd}${(%):-%f}" >&2
          diff <(echo -E $v) <(echo -E ${widgets[$k]:-}) | awk '{print "  " $0}'
        fi
      done
    fi

    if [[ $flags[f] == - ]]; then
      for k v in ${(kv)functions1}; do
        functions[$k]=$v
      done
    elif [[ $flags[f] != '+' ]]; then
      for k v in ${(kv)functions1}; do
        if [[ $v != 'builtin autoload -XU' && $v != ${functions[$k]:-} ]]; then
          echo -E "${(%):-%F{red\}}[WARNING]: function '$k' changed by: ${(@q-)cmd}${(%):-%f}" >&2
          diff <(echo -E $v) <(echo -E ${functions[$k]:-}) | awk '{print "  " $0}'
        fi
      done
    fi

    if [[ $flags[o] == - ]]; then
      emulate zsh                                                   || return
      setopt -- ${(@f)opts1}                                        || return
    elif [[ $flags[o] != '+' ]]; then
      local opts2 && opts2=$(setopt)                                || return
      if [[ $opts1 != $opts2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: options changed by: ${(@q-)cmd}${(%):-%f}" >&2
        diff <(echo -E $opts1) <(echo -E $opts2) | awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[a] == - ]]; then
      unalias -m \*                                                 || return
      eval "$aliases1"                                              || return
    elif [[ $flags[a] != '+' ]]; then
      local aliases2 && aliases2=$(alias -rL; alias -gL; alias -sL) || return
      if [[ $aliases1 != $aliases2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: aliases changed by: ${(@q-)cmd}${(%):-%f}" >&2
        diff <(echo -E $aliases1) <(echo -E $aliases2) | awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[b] == - ]]; then
      bindkey -d                                                    || return
      eval "$bindings1"                                             || return
    elif [[ $flags[b] != '+' ]]; then
      local bindings2 && bindings2=$(bindkey -L)                    || return
      if [[ $bindings1 != $bindings2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: bindings changed by: ${(@q-)cmd}${(%):-%f}" >&2
        diff <(echo -E $bindings1) <(echo -E $bindings2) | awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[t] == - ]]; then
      trap -                                                        || return
      eval $(<$traps1)                                              || return
    elif [[ $flags[t] != '+' ]]; then
      traps2=$(mktemp "${TMPDIR:-/tmp}"/traps2.XXXXXXXXXX)          || return
      trap >$traps2                                                 || return
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
