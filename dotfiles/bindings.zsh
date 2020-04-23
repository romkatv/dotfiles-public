zmodload zsh/terminfo zsh/system
zmodload -F zsh/files b:zf_rm
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

function my-beginning-of-buffer() { CURSOR=0 }
function my-end-of-buffer() { CURSOR=$(($#BUFFER  + 1)) }
function my-expand() { zle _expand_alias || zle .expand-word || true }

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
#   - remove duplicate
#   - proper multi-line command support
#   - preview pane with syntax highlighting
function fzf-history-widget-unique() {
  emulate -L zsh -o pipefail
  local preview='printf "%s" {}'
  (( $+commands[bat] )) && preview+=' | bat -l bash --color always -pp'
  local tmp=${TMPDIR:-/tmp}/zsh-hist.$sysparams[pid]
  {
    print -rNC1 -- "${(@u)history}" |
      fzf --read0 --no-multi --tiebreak=index --cycle --height=80%             \
          --preview-window=down:40%:wrap --preview=$preview                    \
          --bind '?:toggle-preview,ctrl-h:backward-kill-word' --query=$LBUFFER \
      >$tmp || return
    local cmd
    while true; do
      sysread 'cmd[$#cmd+1]' && continue
      (( $? == 5 ))          || return
      break
    done <$tmp
    [[ $cmd == *$'\n' ]] || return
    cmd[-1]=
    [[ -n $cmd ]] || return
    zle .vi-fetch-history -n $(($#history - ${${history[@]}[(ie)$cmd]} + 1))
  } always {
    zf_rm -f -- $tmp
    zle .reset-prompt
  }
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
  zle .reset-prompt
  zle -R
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
    zle .accept-line
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
zle -N my-expand
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
zle -N my-beginning-of-buffer
zle -N my-end-of-buffer

function bindkey() {}

fzf_default_completion=expand-or-complete-with-dots
jit-source ~/dotfiles/fzf/shell/completion.zsh
jit-source ~/dotfiles/fzf/shell/key-bindings.zsh

zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' continuous-trigger alt-enter
jit-source ~/dotfiles/fzf-tab/fzf-tab.zsh

unfunction bindkey

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
bindkey '^ '      my-expand                           # ctrl+space expand alias/glob/parameter
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
bindkey '^[[1;3H' my-beginning-of-buffer
bindkey '^[[1;5H' my-beginning-of-buffer
bindkey '^[[1;3F' my-end-of-buffer
bindkey '^[[1;5F' my-end-of-buffer

typeset -g ZSH_AUTOSUGGEST_EXECUTE_WIDGETS=()
typeset -g ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
  end-of-line
  vi-end-of-line
  vi-add-eol
  my-end-of-buffer
)
typeset -g ZSH_AUTOSUGGEST_CLEAR_WIDGETS=(
  accept-line
  up-line-or-beginning-search
  down-line-or-beginning-search
  up-line-or-beginning-search-local
  down-line-or-beginning-search-local
  fzf-history-widget-unique
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
  forward-char
  vi-forward-char
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
  redisplay
  fzf-tab-complete
)
