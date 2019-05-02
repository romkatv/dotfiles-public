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

# Wrap _expand_alias because putting _expand_alias in ZSH_AUTOSUGGEST_CLEAR_WIDGETS won't work.
function my-expand-alias() { zle _expand_alias }

function expand-or-complete-with-dots() {
  emulate -L zsh
  [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti rmam
  print -Pn "%{%F{red}......%f%}"
  [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti smam
  zle expand-or-complete
  zle redisplay
}

if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  function zle-line-init() { echoti smkx }
  function zle-line-finish() { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

autoload -U edit-command-line up-line-or-beginning-search down-line-or-beginning-search

zle -N edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N my-expand-alias
zle -N expand-or-complete-with-dots
zle -N up-line-or-beginning-search-local
zle -N down-line-or-beginning-search-local

bindkey '^[[3~'   delete-char                         # del        delete one char forward
bindkey '^[OH'    beginning-of-line                   # home       go to the beginning of line
bindkey '^[OF'    end-of-line                         # end        go to the end of line
bindkey '^[[1;5C' forward-word                        # ctrl+right go forward one word
bindkey '^[[1;5D' backward-word                       # ctrl+left  go backward one word
bindkey '^H'      backward-kill-word                  # ctrl+bs    delete previous word
bindkey '^[[3;5~' kill-word                           # ctrl+del   delete next word
bindkey '^J'      backward-kill-line                  # ctrl+j     delete everything before cursor
bindkey '^Z'      undo                                # ctrl+z     undo
bindkey '^[z'     redo                                # alt+z      redo
bindkey '^[OA'    up-line-or-beginning-search-local   # up         prev command in local history
bindkey '^[OB'    down-line-or-beginning-search-local # down       next command in local history
bindkey '^[[1;5A' up-line-or-beginning-search         # ctrl+up    prev command in global history
bindkey '^[[1;5B' down-line-or-beginning-search       # ctrl+down  next command in global history
bindkey '^ '      my-expand-alias                     # ctrl+space expand alias
bindkey '^[[Z'    reverse-menu-complete               # shift+tab  previous in completion menu
bindkey '^E'      edit-command-line                   # ctrl+e     edit command line in $EDITOR
bindkey '^I'      expand-or-complete-with-dots        # tab        show '...' while completing
bindkey '^[[1;3A' dirhistory_zle_dirhistory_up        # alt-up     cd ..
bindkey '^[[1;3B' dirhistory_zle_dirhistory_down      # alt-down   cd in the first subdirectory
bindkey '^[[1;3C' dirhistory_zle_dirhistory_future    # alt-right  cd +1
bindkey '^[[1;3D' dirhistory_zle_dirhistory_back      # alt-left   cd -1

stty susp '^B'  # ctrl+b instead of ctrl+z to suspend (ctrl+z is undo)

typeset -g ZSH_AUTOSUGGEST_EXECUTE_WIDGETS=()
typeset -g ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
  end-of-line
  vi-end-of-line
  vi-add-eol
  # forward-char     # my removal
  # vi-forward-char  # my removal
)
typeset -g ZSH_AUTOSUGGEST_CLEAR_WIDGETS=(
  history-search-forward
  history-search-backward
  history-beginning-search-forward
  history-beginning-search-backward
  history-substring-search-up
  history-substring-search-down
  up-line-or-beginning-search
  down-line-or-beginning-search
  up-line-or-history
  down-line-or-history
  accept-line
  up-line-or-beginning-search-local    # my addition
  down-line-or-beginning-search-local  # my addition
  my-expand-alias                      # my addition
  edit-command-line                    # my addition
)
typeset -g ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(
  forward-word
  emacs-forward-word
  vi-forward-word
  vi-forward-word-end
  vi-forward-blank-word
  vi-forward-blank-word-end
  vi-find-next-char
  vi-find-next-char-skip
  forward-char               # my addition
  vi-forward-char            # my addition
)
