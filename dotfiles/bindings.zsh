() {
  zmodload zsh/terminfo
  autoload -Uz add-zle-hook-widget

  typeset -g __local_searching __local_savecursor

  # This zle widget replaces the standard widget bound to Up (up-line-or-beginning-search). The
  # original widget is bound to Ctrl+Up. The only difference between the two is the history they
  # use. The standard widget uses global history while our replacement uses local history.
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
  # We can attempt to fix this by replacing "up-line-or-beginning-search" with "up-line-or-search"
  # but then we'll be cycling through commands that start with "foo" rather than "foo bar". This is
  # craporama.
  #
  # To solve this problem I copied and modified the definition of down-line-or-beginning-search from
  # https://github.com/zsh-users/zsh/blob/master/Functions/Zle/down-line-or-beginning-search. God
  # bless Open Source.
  function up-line-or-beginning-search-local() {
    emulate -L zsh
    local last=$LASTWIDGET
    zle .set-local-history 1
    if [[ $LBUFFER == *$'\n'* ]]; then
      zle .up-line-or-history
      __local_searching=''
    elif [[ -n $PREBUFFER ]] && zstyle -t ':zle:up-line-or-beginning-search' edit-buffer; then
      zle .push-line-or-edit
    else
      [[ $last = $__local_searching ]] && CURSOR=$__local_savecursor
      __local_savecursor=$CURSOR
      __local_searching=$WIDGET
      zle .history-beginning-search-backward
      zstyle -T ':zle:up-line-or-beginning-search' leave-cursor && zle .end-of-line
    fi
    zle .set-local-history 0
  }

  # Same as above but for Down.
  function down-line-or-beginning-search-local() {
    emulate -L zsh
    local last=$LASTWIDGET
    zle .set-local-history 1
    () {
      if [[ ${+NUMERIC} -eq 0 && ( $last = $__local_searching || $RBUFFER != *$'\n'* ) ]]; then
        [[ $last = $__local_searching ]] && CURSOR=$__local_savecursor
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
    zle .set-local-history 0
  }

  # Wrap _expand_alias because putting _expand_alias in ZSH_AUTOSUGGEST_CLEAR_WIDGETS won't work.
  function my-expand-alias() { zle _expand_alias }

  function expand-or-complete-with-dots() {
    emulate -L zsh
    local c=$(( ${+terminfo[rmam]} && ${+terminfo[smam]} ))
    (( c )) && echoti rmam
    print -Pn "%{%F{red}......%f%}"
    (( c )) && echoti smam
    zle expand-or-complete
    zle redisplay
  }

  function dirhistory-shorten() {
    cd $1 >/dev/null && print -P '%~' || echo -E $1
  }

  function dirhistory-print() {
    local -i max_hist=$1
    local clr=${(%):-%k%f%b}
    (( terminfo[colors] >= 256 )) && local fg=${(%):-%F{244}} || local fg=${(%):-%F{005}}
    local dir out=$clr

    local -i lim=-1
    if (( $#dirhistory_past > max_hist + 2 )); then
      lim=$((max_hist+1))
      out+=$'\n'"$fg... $(($#dirhistory_past - max_hist - 1)) more ...$clr"
    fi
    for dir in ${(Oa)${(Oa)dirhistory_past}[2,lim]}; do
      out+=$'\n'"$fg  $(dirhistory-shorten $dir)$clr"
    done

    out+=$'\n'"* $(dirhistory-shorten $dirhistory_past[-1])"

    local -i lim=-1
    (( $#dirhistory_future > max_hist + 1 )) && lim=max_hist
    for dir in ${${(Oa)dirhistory_future}[1,lim]}; do
      out+=$'\n'"$fg  $(dirhistory-shorten $dir)$clr"
    done
    if (( lim >= 0 )); then
      out+=$'\n'"$fg... $(($#dirhistory_future - max_hist)) more ...$clr"
    fi
    echo -nE $out
  }

  function dirhistory-restore-buffer() {
    emulate -L zsh
    BUFFER=$_DIRHISTORY_BUFFER
    CURSOR=$_DIRHISTORY_CURSOR
    typeset -g _DIRHISTORY_BUFFER=
    typeset -g _DIRHISTORY_CURSOR=1
  }

  function dirhistory_noop() {}

  local which
  for which in noop up back forward; do
    eval "function dirhistory-$which() {
      emulate -L zsh
      typeset -g _DIRHISTORY_BUFFER=\$BUFFER
      typeset -g _DIRHISTORY_CURSOR=\$CURSOR
      BUFFER=
      dirhistory_$which
      zle accept-line
      [[ $which == noop ]] && dirhistory-print 20 || dirhistory-print 3
    }"
  done

  autoload -U edit-command-line up-line-or-beginning-search down-line-or-beginning-search

  zle -N edit-command-line
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  zle -N my-expand-alias
  zle -N expand-or-complete-with-dots
  zle -N up-line-or-beginning-search-local
  zle -N down-line-or-beginning-search-local
  zle -N dirhistory-restore-buffer
  zle -N dirhistory-noop
  zle -N dirhistory-up
  zle -N dirhistory-back
  zle -N dirhistory-forward

  zmodload zsh/terminfo

  if (( $+terminfo[smkx] && $+terminfo[rmkx] )); then
    function enable-term-application-mode() { echoti smkx }
    function disable-term-application-mode() { echoti rmkx }
    zle -N enable-term-application-mode
    zle -N disable-term-application-mode
    add-zle-hook-widget line-init enable-term-application-mode
    add-zle-hook-widget line-finish disable-term-application-mode
  fi

  add-zle-hook-widget line-init dirhistory-restore-buffer

  # Note: You can specify several codes separated by space. All of them will be bound.
  #
  # For example:
  #
  #   CtrlUp '\e[1;5A \e[A'
  #
  # Now, any widget in `bindings` that binds to CtrlUp will be bound to '\e[1;5A' and '\e[A'.
  local -A key_code=(
    Ctrl          '^'
    CtrlDel       '\e[3;5~'
    CtrlBackspace '^H'
    CtrlUp        '\e[1;5A'
    CtrlDown      '\e[1;5B'
    CtrlRight     '\e[1;5C'
    CtrlLeft      '\e[1;5D'
    AltUp         '\e[1;3A'
    AltDown       '\e[1;3B'
    AltRight      '\e[1;3C'
    AltLeft       '\e[1;3D'
    Alt           '\e'
    Tab           '\t'
    Backspace     '^?'
    Delete        '\e[3~'
    Insert        "$terminfo[kich1]"
    Home          "$terminfo[khome]"
    End           "$terminfo[kend]"
    PageUp        "$terminfo[kpp]"
    PageDown      "$terminfo[knp]"
    Up            "$terminfo[kcuu1]"
    Left          "$terminfo[kcub1]"
    Down          "$terminfo[kcud1]"
    Right         "$terminfo[kcuf1]"
    ShiftTab      "$terminfo[kcbt]"
  )

  local -a bindings=(
    Backspace     backward-delete-char                 # delete one char backward
    Delete        delete-char                          # delete one char forward
    Home          beginning-of-line                    # go to the beginning of line
    End           end-of-line                          # go to the end of line
    CtrlRight     forward-word                         # go forward one word
    CtrlLeft      backward-word                        # go backward one word
    CtrlBackspace backward-kill-word                   # delete previous word
    CtrlDel       kill-word                            # delete next word
    Ctrl-J        backward-kill-line                   # delete everything before cursor
    Ctrl-Z        undo                                 # undo (suspend is on Ctrl-B)
    Alt-Z         redo                                 # redo
    Left          backward-char                        # move cursor one char backward
    Right         forward-char                         # move cursor one char forward
    Up            up-line-or-beginning-search-local    # prev command in local history
    Down          down-line-or-beginning-search-local  # next command in local history
    CtrlUp        up-line-or-beginning-search          # prev command in global history
    CtrlDown      down-line-or-beginning-search        # next command in global history
    Ctrl-' '      my-expand-alias                      # expand alias
    ShiftTab      reverse-menu-complete                # previous in completion menu
    Ctrl-E        edit-command-line                    # edit command line in $EDITOR
    Tab           expand-or-complete-with-dots         # show '...' while completing
    AltUp         dirhistory-up                        # cd ..
    AltDown       dirhistory-noop                      # print directory history
    AltLeft       dirhistory-back                      # cd into the previous directory
    AltRight      dirhistory-forward                   # cd into the next directory
  )

  local key widget
  for key widget in $bindings[@]; do
    local -a code=('')
    local part=''
    for part in ${(@ps:-:)key}; do
      if [[ $#part == 1 ]]; then
        code=${^code}${(L)part}
      elif [[ -n $key_code[$part] ]]; then
        local -a p=(${(@ps: :)key_code[$part]})
        code=(${^code}${^p})
      else
        (( $+key_code[$part] )) || echo -E "[ERROR] undefined key: $part" >&2
        code=()
        break
      fi
    done
    local c=''
    for c in $code[@]; do bindkey $c $widget; done
  done

  stty susp '^B'  # Ctrl-B instead of Ctrl-Z to suspend (Ctrl-Z is undo)

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

  typeset -g ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(
    orig-\*
    beep
    run-help
    set-local-history
    which-command
    yank
    yank-pop
    zle-isearch-update
    zle-keymap-select
    zle-line-finish      # my addition
	)
}
