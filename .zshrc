export ZSH=$HOME/.oh-my-zsh

ZSH_THEME=powerlevel10k/powerlevel10k

# GITSTATUS_ENABLE_LOGGING=1
# POWERLEVEL9K_DISABLE_GITSTATUS=true
# GITSTATUS_DAEMON=~/.oh-my-zsh/custom/plugins/gitstatus/gitstatusd
# POWERLEVEL9K_GITSTATUS_DIR=~/.oh-my-zsh/custom/plugins/gitstatus
# POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=1
# (( WSL )) && POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096

ZLE_REMOVE_SUFFIX_CHARS=      # don't eat the space when typing '|' after a tab completion
ZSH_DISABLE_COMPFIX=true      # don't complain about permissions when completing
ENABLE_CORRECTION=true        # zsh: correct 'sl' to 'ls' [nyae]?
COMPLETION_WAITING_DOTS=true  # show "..." while completing

plugins=(
  zsh-prompt-benchmark     # function zsh_prompt_benchmark to benchmark prompt
  zsh-syntax-highlighting  # syntax highlighting for prompt
  zsh-autosuggestions      # suggests commands as you type, based on command history (grey text)
  command-not-found        # use ubuntu's command-not-found on unrecognized command
  dirhistory               # alt-left and alt-right to navigate dir history; alt-up for `cd ..`
  extract                  # `extract <archive>` command
  z                        # `z` command to cd into commonly used directories
)

source $HOME/bin/local-history.zsh
source $HOME/.powerlevel9krc
source $ZSH/oh-my-zsh.sh

ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  up-line-or-beginning-search-local
  down-line-or-beginning-search-local
)

zle_highlight=(default:bold)  # bold prompt

alias clang-format='clang-format -style=file'
alias ls='ls --group-directories-first --color=auto'
alias gedit='gedit &>/dev/null'                       # suppress useless warnings
alias d2u='dos2unix'
alias u2d='unix2dos'

# If you want some random config file to be versioned in the dotfiles-public git repo, type
# `dotfiles-public add -f <random-file>`. Use `commit`, `push`, etc., as with normal git.
alias dotfiles-public='git --git-dir=$HOME/.dotfiles-public/.git --work-tree=$HOME'
alias dotfiles-private='git --git-dir=$HOME/.dotfiles-private/.git --work-tree=$HOME'

alias x='xsel --clipboard -i'  # cut to clipboard
alias v='xsel --clipboard -o'  # paste from clipboard
alias c='x && v'               # copy to clipboard

if (( WSL )); then
  # Prints Windows environment variable $1.
  function win_env() {
    emulate -L zsh
    echo -E ${$(/mnt/c/Windows/System32/cmd.exe /c "echo %$1%")%$'\r'}
  }
fi

# Automatically run `ls` after every `cd`.
# function _chpwd_hook_ls() ls
# autoload -Uz add-zsh-hook
# add-zsh-hook chpwd _chpwd_hook_ls

bindkey '^H'      backward-kill-word                  # ctrl+bs   delete previous word
bindkey '^[[3;5~' kill-word                           # ctrl+del  delete next word
bindkey '^J'      backward-kill-line                  # ctrl+j    delete everything before cursor
bindkey '^Z'      undo                                # ctrl+z    undo
bindkey '^Y'      redo                                # ctrl+y    redo
bindkey '^[OA'    up-line-or-beginning-search-local   # up        previous command in local history
bindkey '^[OB'    down-line-or-beginning-search-local # down      next command in local history
bindkey '^[[1;5A' up-line-or-beginning-search         # ctrl+up   previous command in global history
bindkey '^[[1;5B' down-line-or-beginning-search       # ctrl+down next command in global history

stty susp '^B'  # ctrl+b instead of ctrl+z to suspend (ctrl+z is undo)

HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILESIZE=1000000000

setopt HIST_IGNORE_SPACE     # don't add commands starting with space to history
setopt HIST_VERIFY           # if a cmd triggers history expansion, show it instead of running
setopt HIST_REDUCE_BLANKS    # remove junk whitespace from commands before adding to history
setopt EXTENDED_GLOB         # (#qx) glob qualifier and more
setopt NO_BANG_HIST          # disable old history syntax
setopt GLOB_DOTS             # glob matches files starting with dot; `*` becomes `*(D)`
setopt MULTIOS               # allow multiple redirections for the same fd
setopt NO_BG_NICE            # don't nice background jobs; not useful and doesn't work on WSL

# This affects every invocation of `less`.
#
#   -R   color
#   -F   exit if there is less than one page of content
#   -X   keep content on screen after exit
#   -M   show more info at the bottom prompt line
#   -x4  tabs are 4 instead of 8
export LESS=-RFXMx4

if [[ -f $HOME/.zshrc-private ]]; then
  source $HOME/.zshrc-private
fi
