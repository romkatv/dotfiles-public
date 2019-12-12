alias diff='diff --color=auto'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias clang-format='clang-format -style=file'
alias ls='ls --color=auto --group-directories-first -A'
alias tree='tree -aC -I .git --dirsfirst'
alias gedit='gedit &>/dev/null'

alias dotfiles-public='git --git-dir="$HOME"/.dotfiles-public --work-tree="$HOME"'
alias dotfiles-private='git --git-dir="$HOME"/.dotfiles-private --work-tree="$HOME"'

alias x='xclip -selection clipboard -in'          # cut to clipboard
alias v='xclip -selection clipboard -out'         # paste from clipboard
alias c='xclip -selection clipboard -in -filter'  # copy clipboard

if (( WSL )); then
  hash -d r=/mnt/d/r
  hash -d h="$(wslpath "$(win-env USERPROFILE)")"
  alias np='"/mnt/c/Program Files/Notepad++/notepad++.exe"'
fi

