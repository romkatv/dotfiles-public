zmodload zsh/terminfo
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search run-help

(( $+aliases[run-help] )) && unalias run-help

function up-line-or-beginning-search-local() {
  emulate -L zsh
  local last=$LASTWIDGET
  zle .set-local-history 1
  () { local -h LASTWIDGET=$last; up-line-or-beginning-search "$@" } "$@"
  zle .set-local-history 0
}

function down-line-or-beginning-search-local() {
  emulate -L zsh
  local last=$LASTWIDGET
  zle .set-local-history 1
  () { local -h LASTWIDGET=$last; down-line-or-beginning-search "$@" } "$@"
  zle .set-local-history 0
}

# Wrap _expand_alias because putting _expand_alias in ZSH_AUTOSUGGEST_CLEAR_WIDGETS won't work.
function my-expand-alias() { zle _expand_alias || true }
# When using stock run-help with syntax highlighting and autosuggestions, you'll get weird results
# for `exec` with `exec zsh` as autosuggestion. This fixes one half of the problem.
function my-run-help() { zle run-help || true }

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
  local preview='zsh -dfc "setopt extended_glob; echo - \${\${1#*[0-9] }## #}" -- {}'
  (( $+commands[bat] )) && preview+=' | bat -l bash --color always -pp'
  local selected
  selected="$(
    fc -rl 1 |
    awk '!_[substr($0, 8)]++' |
    fzf +m -n2..,.. --tiebreak=index --cycle --height=80% --preview-window=down:30%:wrap \
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

function my-do-nothing() {}

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N my-expand-alias
zle -N my-run-help
zle -N expand-or-complete-with-dots
zle -N up-line-or-beginning-search-local
zle -N down-line-or-beginning-search-local
zle -N cd-back
zle -N cd-forward
zle -N cd-up
zle -N fzf-history-widget-unique
zle -N toggle-dotfiles
zle -N my-pound-insert
zle -N my-do-nothing

bindkey -e

fzf_default_completion=expand-or-complete-with-dots
jit-source ~/dotfiles/fzf/shell/completion.zsh
jit-source ~/dotfiles/fzf/shell/key-bindings.zsh
bindkey -r '^[c'  # remove unwanted binding

FZF_TAB_PREFIX=
FZF_TAB_SHOW_GROUP=brief
FZF_TAB_SINGLE_GROUP=()
FZF_TAB_CONTINUOUS_TRIGGER='alt-enter'

# fzf-tab reads the value of this binding during initialization.
bindkey '\t' expand-or-complete
jit-source ~/dotfiles/fzf-tab/fzf-tab.zsh

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
bindkey '^[[5~'   my-do-nothing                       # pageup     do nothing
bindkey '^[[6~'   my-do-nothing                       # pagedown   do nothing
bindkey '^[h'     my-run-help                         # alt+h      help for the command at cursor
bindkey '^[H'     my-run-help                         # alt+H      help for the command at cursor

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
  fzf-tab-complete                     # my addition
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
  zle-\*
  expand-or-complete  # my addition (to make expand-or-complete-with-dots work with fzf-tab)
)
