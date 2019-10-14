alias diff='diff --color=auto'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias clang-format='clang-format -style=file'
alias ls='ls --group-directories-first --color=auto'
alias tree='tree -aC -I .git --dirsfirst'
alias gedit='gedit &>/dev/null'
alias d2u='dos2unix'
alias u2d='unix2dos'

if [[ -d ~/.dotfiles-public ]]; then
  alias dotfiles-public='git --git-dir="$HOME"/.dotfiles-public/.git --work-tree="$HOME"'
fi
if [[ -d ~/.dotfiles-private ]]; then
  alias dotfiles-private='git --git-dir="$HOME"/.dotfiles-private/.git --work-tree="$HOME"'
fi

alias x='xsel --clipboard -i'  # cut to clipboard
alias v='xsel --clipboard -o'  # paste from clipboard
alias c='x && v'               # copy to clipboard

if (( WSL )); then
  hash -d r=/mnt/d/r
  hash -d h="$(wslpath "$(win_env USERPROFILE)")"
fi
