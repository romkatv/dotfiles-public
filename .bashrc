[[ $- == *i* ]] || return  # non-interactive shell

HISTCONTROL=ignoreboth
HISTSIZE=1000000000
HISTFILESIZE=1000000000
HISTFILE="$HOME"/.bash_history

shopt -s histappend
shopt -s checkwinsize
shopt -s globstar

command -v lesspipe &>/dev/null && eval "$(SHELL=/bin/sh lesspipe)"
command -v dircolors &>/dev/null && eval "$(dircolors -b)"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

if [ -f /usr/share/bash-completion/bash_completion ]; then
  source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
fi

if [[ -d ~/gitstatus ]]; then
  GITSTATUS_ENABLE_LOGGING=1
  GITSTATUS_DAEMON=~/gitstatus/gitstatusd
  source ~/gitstatus/gitstatus.prompt.sh
else
  source ~/dotfiles/gitstatus/gitstatus.prompt.sh
fi
