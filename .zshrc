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

HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILESIZE=1000000000

alias clang-format='/usr/bin/clang-format -style=file'
alias ls='ls --group-directories-first --color=tty'
alias gedit='gedit &>/dev/null'

alias dotfiles-public='git --git-dir="$HOME"/.dotfiles-public/ --work-tree="$HOME"'
alias dotfiles-private='git --git-dir="$HOME"/.dotfiles-private/ --work-tree="$HOME"'

alias x='xsel --clipboard -i' # cut to clipboard
alias v='xsel --clipboard -o' # paste from clipboard
alias c='x && v'              # copy to clipboard

bindkey '^H'      backward-kill-word # ctrl+backspace
bindkey '^[[3;5~' kill-word          # ctrl+del
bindkey '^J'      backward-kill-line # ctrl+j

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
unsetopt BG_NICE
unsetopt COMPLETE_ALIASES

if [[ "$WSL" == 1 ]]; then
  cd
fi
