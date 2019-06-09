# Usage: run-tracked [ {+|-}wfeoabt ] cmd...
#
# Runs `cmd...` and takes action when it detects changes in the global environment.
#
# Types of environment that run-tracked can monitor:
#
#   TYPE  DESCRIPTION
#      w  zle widgets
#      f  functions
#      e  exported parameters
#      o  options
#      a  aliases
#      b  bindings
#      t  traps
#
# For every type of environment the default action on detected changes is to print a warning.
# Options prefixed with `+` cause changes to be accepted without a warning. Options prefixed
# with '-' cause changes to be reverted, also without a warning.
#
# For zle widgets and functions, new entities are not considered changes. For all other
# environments they are. That is, it's absolutely fine for a sourced file to define a new
# function, but it's not fine (unless explicitly allowed) to define an alias or a key binding
# even if they don't clash with existing aliases/bindings.
#
# The primary purpose of `run-tracked` is to provide a modicum of protection against clashes when
# sourcing ZSH plugins. It can help with the following problems:
#
#   * Ensure that plugins doesn't override each others' and your own functions, zle widgets,
#     key bindings and traps.
#   * Make use of certain definitions provided by a plugin (e.g., functions) without accepting
#     a bundle of crap with them (say, aliases and key bindings).
#   * Avoid environment polution by overeager plugins that slap `extern` on variables for no reason.
#   * Prevent plugins from changing shell options without your knowledge.
#
# The solution is to source plugins with `run-tracked source /path/to/plugin.zsh` after
# defining your own widgets, functions, aliases, key bindings, etc. By doing it in this order you
# ensure that *your* stuff (functions, etc.) don't accidentally override plugins' definitions.
# When `run-tracked` prints a warning (for example, saying that the plugin has defined a key
# binding), you need to decide whether to accept the changes (`+b`) or reject them (`-b`).
#
# Note that you won't be able to manually run `source ~/.zshrc` if you are using `run-tracked`.
# Not a big loss since it's a bad practice anyway. Instead, run `exec zsh` to apply configuration
# changes.
#
# Example:
#
#   run-tracked source /path/to/plugin.zsh
#
# Output:
#
#   [WARNING]: exported vars changed by: source /path/to/plugin.zsh
#     39c39
#     < PATH=/usr/bin:/bin
#     ---
#     < PATH=/usr/bin:/bin:/random/crap
#   [WARNING]: bindings changed by: source /path/to/plugin.zsh
#     23a24
#     > bindkey "^X" something-awesome
#
# Apart from these warnings, the effect of `run-tracked source /path/to/plugin.zsh` is the same as
# of `source /path/to/plugin.zsh`.
#
# Suppose you want to accept the new key binding but not the override of PATH. Add `+b` and `-e`
# to the invocation of `run-tracked`:
#
#   run-tracked +b -e source /path/to/plugin.zsh
#
# Now there are no warnings and PATH stays unchanged.
function run-tracked() {
  local -i finished=0
  local traps1 traps2

  {
    local opt
    local -A flags
    while getopts "wfeoabt" opt; do
      case $opt in
        '?') return 1;;
        +*) flags[${opt:1}]=+;;
        *) flags[$opt]=-;;
      esac
    done

    local -a cmd=("${(@)*:$OPTIND}")

    local -A widgets1=(${(kv)widgets})
    local -A functions1=(${(kv)functions})
    local env1 && env1=$(typeset -x)                                || return
    local opts1 && opts1=$(setopt)                                  || return
    local aliases1 && aliases1=$(alias -rL; alias -gL; alias -sL)   || return
    local bindings1 && bindings1=$(bindkey -L)                      || return
    traps1=$(command mktemp "${TMPDIR:-/tmp}"/traps1.XXXXXXXXXX)    || return
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
          command diff <(echo -E $v) <(echo -E ${widgets[$k]:-}) | command awk '{print "  " $0}'
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
          command diff <(echo -E $v) <(echo -E ${functions[$k]:-}) | command awk '{print "  " $0}'
        fi
      done
    fi

    if [[ $flags[e] == - ]]; then
      local env2 && env2=$(typeset +x)                              || return
      typeset +x -- ${(@f)env2}                                     || return
      eval "typeset -x -- ${(@fz)env1}"                             || return
    elif [[ $flags[e] != '+' ]]; then
      local env2 && env2=$(typeset -x)                              || return
      if [[ $env1 != $env2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: exported vars changed by: ${(@q-)cmd}${(%):-%f}" >&2
        command diff <(echo -E $env1) <(echo -E $env2) | command awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[o] == - ]]; then
      emulate zsh                                                   || return
      setopt -- ${(@f)opts1}                                        || return
    elif [[ $flags[o] != '+' ]]; then
      local opts2 && opts2=$(setopt)                                || return
      if [[ $opts1 != $opts2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: options changed by: ${(@q-)cmd}${(%):-%f}" >&2
        command diff <(echo -E $opts1) <(echo -E $opts2) | command awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[a] == - ]]; then
      unalias -m \*                                                 || return
      eval "$aliases1"                                              || return
    elif [[ $flags[a] != '+' ]]; then
      local aliases2 && aliases2=$(alias -rL; alias -gL; alias -sL) || return
      if [[ $aliases1 != $aliases2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: aliases changed by: ${(@q-)cmd}${(%):-%f}" >&2
        command diff <(echo -E $aliases1) <(echo -E $aliases2) | command awk '{print "  " $0}'
      fi
    fi

    if [[ $flags[b] == - ]]; then
      bindkey -d                                                    || return
      eval "$bindings1"                                             || return
    elif [[ $flags[b] != '+' ]]; then
      local bindings2 && bindings2=$(bindkey -L)                    || return
      if [[ $bindings1 != $bindings2 ]]; then
        echo -E "${(%):-%F{red\}}[WARNING]: bindings changed by: ${(@q-)cmd}${(%):-%f}" >&2
        command diff <(echo -E $bindings1) <(echo -E $bindings2) | command awk '{print "  " $0}'
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
        command diff $traps1 $traps2 | command awk '{print "  " $0}'
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
  # Prints the value of Windows environment variable $1 or "%$1%" if there is
  # no such variable.
  function win_env() {
    emulate -L zsh
    (( ARGC == 1 && $#1 )) || { echo 'usage: win_env <name>' >&2; return 1 }
    local val && val=$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c "echo %$1%") || return
    echo -E ${val%$'\r'}
  }
  # The same as double-cliking on file/dir $1 in Windows Explorer.
  function xopen() {
    emulate -L zsh
    (( ARGC == 1 && $#1 )) || { echo 'usage: xopen <path>' >&2; return 1 }
    local arg && arg=$(wslpath -w "$1") || return
    /mnt/c/Windows/System32/cmd.exe /c start "$arg"
  }
else
  # The same as double-cliking on file/dir $1 in X File Manager.
  function xopen() {
    emulate -L zsh
    xdg-open "$@" &>/dev/null &!
  }
fi
