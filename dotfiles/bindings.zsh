() {
  zmodload zsh/terminfo
  autoload -Uz add-zle-hook-widget
  autoload -Uz edit-command-line
  autoload -Uz up-line-or-beginning-search
  autoload -Uz down-line-or-beginning-search

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

  # Shows '...' while completing. No `emulate -L zsh` to pick up dotglob if it's set.
  if (( ${+terminfo[rmam]} && ${+terminfo[smam]} )); then
    function expand-or-complete-with-dots() {
      echo -nE - ${terminfo[rmam]}${(%):-"%F{red}......%f"}${terminfo[smam]}
      zle expand-or-complete
      zle redisplay
    }
  else
    function expand-or-complete-with-dots() {
      zle expand-or-complete
    }
  fi

  # Similar to fzf-history-widget. Extras:
  #
  #   - `awk` to remove duplicate
  #   - preview pane with syntax highlighting
  function fzf-history-widget-unique() {
    local selected
    setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
    local preview='echo -E {} | cut -c8- | xargs -0 echo -e | bat -l bash --color always -pp'
    selected="$(
      fc -rl 1 |
      awk '!_[substr($0, 8)]++' |
      $(__fzfcmd) +m -n2..,.. --tiebreak=index --height=80% --preview-window=down:50% \
        --query=$LBUFFER --preview=$preview )"
    local ret=$?
    [[ -n "$selected" ]] && zle vi-fetch-history -n $selected
    zle .reset-prompt
    return $ret
  }

  function redraw-prompt() {
    emulate -L zsh
    zle || return
    local f
    for f in precmd $precmd_functions; do
      (( $+functions[$f] )) && $f &>/dev/null
    done
    zle .reset-prompt && zle -R
  }

  function cd-rotate() {
    emulate -L zsh
    while (( $#dirstack )) && ! pushd -q $1 &>/dev/null; do
      popd -q $1
    done
    if (( $#dirstack )); then
      local f
      for f in chpwd $chpwd_functions; do
        (( $+functions[$f] )) && $f
      done
      redraw-prompt
    fi
  }

  function cd-back() { cd-rotate +1 }
  function cd-forward() { cd-rotate -0 }
  function cd-up() { cd .. && redraw-prompt }

  zle -N edit-command-line
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  zle -N my-expand-alias
  zle -N expand-or-complete-with-dots
  zle -N up-line-or-beginning-search-local
  zle -N down-line-or-beginning-search-local
  zle -N cd-back
  zle -N cd-forward
  zle -N cd-up
  zle -N fzf-history-widget-unique

  fzf_default_completion=expand-or-complete-with-dots

  # Deny fzf bindings. We have our own.
  function bindkey() {}
  jit-source ~/dotfiles/fzf/shell/completion.zsh
  jit-source ~/dotfiles/fzf/shell/key-bindings.zsh
  unfunction bindkey

  # Note: You can specify several codes separated by space. All of them will be bound.
  #
  # For example:
  #
  #   Up '\eOA \e[A'
  #
  # Now, any widget in `bindings` that binds to Up will be bound to '\eOA' and '\e[A'.
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
    Insert        '\e[2~'
    Home          '\eOH \e[H'
    End           '\eOF \e[F'
    PageUp        '\e[5~ '
    PageDown      '\e[6~'
    Up            '\eOA \e[A'
    Left          '\eOD \e[D'
    Down          '\eOB \e[B'
    Right         '\eOC \e[C'
    ShiftTab      '\e[Z'
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
    Left          backward-char                        # move cursor one char backward
    Right         forward-char                         # move cursor one char forward
    Up            up-line-or-beginning-search-local    # prev command in local history
    Down          down-line-or-beginning-search-local  # next command in local history
    CtrlUp        up-line-or-beginning-search          # prev command in global history
    CtrlDown      down-line-or-beginning-search        # next command in global history
    Ctrl-' '      my-expand-alias                      # expand alias
    ShiftTab      reverse-menu-complete                # previous in completion menu
    Ctrl-E        edit-command-line                    # edit command line in $EDITOR
    AltLeft       cd-back                              # cd into the previous directory
    AltRight      cd-forward                           # cd into the next directory
    AltUp         cd-up                                # cd ..
    Tab           expand-or-complete-with-dots         # completion with '...' while running
    AltDown       fzf-cd-widget                        # fzf cd
    Ctrl-T        fzf-completion                       # fzf completion
    Ctrl-R        fzf-history-widget-unique            # fzf history
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
    fzf-history-widget-unique            # my addition
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
}
