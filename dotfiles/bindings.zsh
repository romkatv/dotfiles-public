zmodload zsh/terminfo
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
    echo -nE - ${terminfo[rmam]}${(%):-"%F{red}...%f"}${terminfo[smam]}
    zle fzf-tab-complete
  }
else
  function expand-or-complete-with-dots() {
    zle fzf-tab-complete
  }
fi

# Similar to fzf-history-widget. Extras:
#
#   - `awk` to remove duplicate
#   - preview pane with syntax highlighting
function fzf-history-widget-unique() {
  emulate -L zsh -o pipefail
  local preview='echo -E {} | cut -c8- | xargs -0 echo -e | bat -l bash --color always -pp'
  local selected
  selected="$(
    fc -rl 1 |
    awk '!_[substr($0, 8)]++' |
    fzf +m -n2..,.. --tiebreak=index --cycle --height=80% --preview-window=down:25%:wrap \
      --query=$LBUFFER --preview=$preview)"
  local ret=$?
  [[ -n "$selected" ]] && zle vi-fetch-history -n $selected
  zle .reset-prompt
  return ret
}

function redraw-prompt() {
  emulate -L zsh
  local chpwd=${1:-0} f
  if (( chpwd )); then
    for f in chpwd $chpwd_functions; do
      (( $+functions[$f] )) && $f &>/dev/null
    done
  fi
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
    redraw-prompt 1
  fi
}

function cd-back() { cd-rotate +1 }
function cd-forward() { cd-rotate -0 }
function cd-up() { cd .. && redraw-prompt 1 }

function my-pound-insert() {
  emulate -L zsh -o extended_glob
  local lines=("${(@f)BUFFER}")
  local uncommented=(${lines:#'#'*})
  if (( $#uncommented )); then
    local MATCH
    BUFFER="${(pj:\n:)${(@)lines:/(#m)*/#${MATCH#\#}}}"
    zle accept-line
  else
    local lbuf=$LBUFFER cur=$CURSOR
    BUFFER="${(pj:\n:)${(@)lines#\#}}"
    if (( $#lbuf )); then
      lines=("${(@f)lbuf[1,-2]}")
      CURSOR=$((cur-$#lines))
    fi
  fi
}

function toggle-dotfiles() {
  emulate -L zsh
  case $GIT_DIR in
    '')
      export GIT_DIR=~/.dotfiles-public
      export GIT_WORK_TREE=~
    ;;
    ~/.dotfiles-public)
      export GIT_DIR=~/.dotfiles-private
      export GIT_WORK_TREE=~
    ;;
    *)
      unset GIT_DIR
      unset GIT_WORK_TREE
    ;;
  esac
  redraw-prompt 0
}

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
zle -N toggle-dotfiles
zle -N my-pound-insert

fzf_default_completion=expand-or-complete-with-dots
FZF_TAB_OPTS='--cycle --layout=reverse --tiebreak=begin --bind tab:down,shift-tab:up --height=50%'

# Deny fzf bindings. We have our own.
function bindkey() {}
jit-source ~/dotfiles/fzf/shell/completion.zsh
jit-source ~/dotfiles/fzf/shell/key-bindings.zsh
jit-source ~/dotfiles/fzf-tab/fzf-tab.zsh
unfunction bindkey

bindkey -e

# If NumLock is off, translate keys to make them appear the same as with NumLock on.
bindkey -s '^[OM' '^M'  # enter
bindkey -s '^[Ok' '+'
bindkey -s '^[Om' '-'
bindkey -s '^[Oj' '*'
bindkey -s '^[Oo' '/'
bindkey -s '^[OX' '='

# If someone switches our terminal to application mode (smkx), translate keys to make
# them appear the same as in raw mode (rmkx).
bindkey -s '^[OH' '^[[H'  # home
bindkey -s '^[OF' '^[[F'  # end
bindkey -s '^[OA' '^[[A'  # up
bindkey -s '^[OB' '^[[B'  # down
bindkey -s '^[OD' '^[[D'  # left
bindkey -s '^[OC' '^[[C'  # right

# TTY sends different key codes. Translate them to regular.
bindkey -s '^[[1~' '^[[H'  # home
bindkey -s '^[[4~' '^[[F'  # end

bindkey '^[[D'    backward-char                       # left       move cursor one char backward
bindkey '^[[C'    forward-char                        # right      move cursor one char forward
bindkey '^[[A'    up-line-or-beginning-search-local   # up         prev command in local history
bindkey '^[[B'    down-line-or-beginning-search-local # down       next command in local history
bindkey '^[[H'    beginning-of-line                   # home       go to the beginning of line
bindkey '^[[F'    end-of-line                         # end        go to the end of line
bindkey '^?'      backward-delete-char                # bs         delete one char backward
bindkey '^[[3~'   delete-char                         # delete     delete one char forward
bindkey '^[[1;5C' forward-word                        # ctrl+right go forward one word
bindkey '^[[1;5D' backward-word                       # ctrl+left  go backward one word
bindkey '^H'      backward-kill-word                  # ctrl+bs    delete previous word
bindkey '^[[3;5~' kill-word                           # ctrl+del   delete next word
bindkey '^K'      kill-line                           # ctrl+k     delete line after cursor
bindkey '^J'      backward-kill-line                  # ctrl+j     delete line before cursor
bindkey '^N'      kill-buffer                         # ctrl+n     delete all lines
bindkey '^_'      undo                                # ctrl+/     undo
bindkey '^\'      redo                                # ctrl+\     redo
bindkey '^Y'      my-pound-insert                     # ctrl+y     comment and accept, or uncomment
bindkey '^[[1;5A' up-line-or-beginning-search         # ctrl+up    prev command in global history
bindkey '^[[1;5B' down-line-or-beginning-search       # ctrl+down  next command in global history
bindkey '^ '      my-expand-alias                     # ctrl+space expand alias
bindkey '^[[Z'    reverse-menu-complete               # shift+tab  previous in completion menu
bindkey '^[[1;3D' cd-back                             # alt+left   cd into the previous directory
bindkey '^[[1;3C' cd-forward                          # alt+right  cd into the next directory
bindkey '^[[1;3A' cd-up                               # alt+up     cd ..
bindkey '\t'      expand-or-complete-with-dots        # tab        completion with '...'
bindkey '^[[1;3B' fzf-cd-widget                       # alt+down   fzf cd
bindkey '^T'      fzf-completion                      # ctrl+t     fzf completion
bindkey '^R'      fzf-history-widget-unique           # ctrl+r     fzf history
bindkey '^P'      toggle-dotfiles                     # ctrl+p     toggle public/private dotfiles

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
  fzf-tab-complete           # my addition
)
