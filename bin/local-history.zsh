typeset -g __local_searching __local_savecursor

# This zle widget replaces the standard widget bound to Up (up-line-or-beginning-search). The
# original widget is bound to Ctrl+Up. The only difference between the two is the history they use.
# The standard widget uses global history while our replacement uses local history.
#
# Ideally, this function would be implemented like this:
#
#   zle .set-local-history 1
#   zle .up-line-or-beginning-search
#   zle .set-local-history 0
#
# This doesn't work though. If you type "foo bar" and press Up once, you'll get the last command
# from local history that starts with "foo bar", such as "foo bar baz". This is great. However, if
# you press Up again, you'll get the previous command from local history that starts with
# "foo bar baz" rather than with "foo bar". This is brokarama.
#
# We can attempt to fix this by replacing "up-line-or-beginning-search" with "up-line-or-search" but
# then we'll be cycling through commands that start with "foo" rather than "foo bar". This is
# craporama.
#
# To solve this problem I copied and modified the definition of down-line-or-beginning-search from
# https://github.com/zsh-users/zsh/blob/master/Functions/Zle/down-line-or-beginning-search. God
# bless Open Source.
function up-line-or-beginning-search-local() {
  emulate -L zsh
  local LAST=$LASTWIDGET
  zle .set-local-history 1
  if [[ $LBUFFER == *$'\n'* ]]; then
    zle .up-line-or-history
    __local_searching=''
  elif [[ -n $PREBUFFER ]] && zstyle -t ':zle:up-line-or-beginning-search' edit-buffer; then
    zle .push-line-or-edit
  else
    [[ $LAST = $__local_searching ]] && CURSOR=$__local_savecursor
    __local_savecursor=$CURSOR
    __local_searching=$WIDGET
    zle .history-beginning-search-backward
    zstyle -T ':zle:up-line-or-beginning-search' leave-cursor && zle .end-of-line
  fi
  builtin zle set-local-history 0
}

# Same as above but for Down.
function down-line-or-beginning-search-local() {
  emulate -L zsh
  local LAST=$LASTWIDGET
  zle .set-local-history 1
  function impl() {
    if [[ ${+NUMERIC} -eq 0 && ( $LAST = $__local_searching || $RBUFFER != *$'\n'* ) ]]; then
      [[ $LAST = $__local_searching ]] && CURSOR=$__local_savecursor
      __local_searching=$WIDGET
      __local_savecursor=$CURSOR
      if zle .history-beginning-search-forward; then
        if [[ $RBUFFER != *$'\n'* ]]; then
          zstyle -T ':zle:down-line-or-beginning-search' leave-cursor && zle .end-of-line
        fi
        return
      fi
      [[ $RBUFFER = *$'\n'* ]] || return
    fi
    __local_searching=''
    zle .down-line-or-history
  }
  impl
  zle .set-local-history 0
}

zle -N up-line-or-beginning-search-local
zle -N down-line-or-beginning-search-local
