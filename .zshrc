export ZSH=$HOME/.oh-my-zsh

# See https://github.com/bhilburn/powerlevel9k for configuration options.
# TODO: Add a custom element that can be hooked by mkport-env.
ZSH_THEME='powerlevel9k/powerlevel9k'
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_ROOT_ICON="\uF09C"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='grey'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND='green'
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(root_indicator dir_writable dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)

ZLE_REMOVE_SUFFIX_CHARS=''
ZSH_DISABLE_COMPFIX=true
ENABLE_CORRECTION=true
COMPLETION_WAITING_DOTS=true

plugins=(git zsh-syntax-highlighting zsh-autosuggestions command-not-found dirhistory extract)

source $ZSH/oh-my-zsh.sh

alias clang-format='clang-format -style=file'
alias ls='ls --group-directories-first --color=tty'
alias gedit='gedit &>/dev/null'

alias dotfiles-public='git --git-dir="$HOME"/.dotfiles-public/ --work-tree="$HOME"'
alias dotfiles-private='git --git-dir="$HOME"/.dotfiles-private/ --work-tree="$HOME"'

alias x='xsel --clipboard -i'  # cut to clipboard
alias v='xsel --clipboard -o'  # paste from clipboard
alias c='x && v'               # copy to clipboard

stty susp '^B'  # ctrl+b instead of ctrl+z to suspend

bindkey '^H'      backward-kill-word  # ctrl+backspace -- delete previous word
bindkey '^[[3;5~' kill-word           # ctrl+del       -- delete next word
bindkey '^J'      backward-kill-line  # ctrl+j         -- delete everything before cursor
bindkey '^Z'      undo                # ctrl+z         -- undo
bindkey '^Y'      redo                # ctrl+y         -- redo

HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILESIZE=1000000000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDEDGLOB
setopt NOEQUALS
setopt NOBANGHIST

unsetopt BG_NICE

# Colored man pages.
function man() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m")    \
    LESS_TERMCAP_md=$(printf "\e[1;31m")    \
    LESS_TERMCAP_me=$(printf "\e[0m")       \
    LESS_TERMCAP_se=$(printf "\e[0m")       \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m")       \
    LESS_TERMCAP_us=$(printf "\e[1;36m")    \
    man "$@"
}

# Run `ls` after every `cd`.
function chpwd() { ls }

if [[ "$WSL" == 1 ]]; then
  cd
fi
