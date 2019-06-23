umask 0002
ulimit -c unlimited

export WSL=$(grep -q Microsoft /proc/version && echo 1 || echo 0)
export EDITOR=$HOME/bin/redit
export PAGER=less
export GOPATH=$HOME/go

typeset -gaU cdpath fpath mailpath path
path=($HOME/bin $HOME/.local/bin $HOME/.cargo/bin ${path[@]})

# This affects every invocation of `less`.
#
#   -i   case-insensitive search unless search string contains uppercase letters
#   -R   color
#   -F   exit if there is less than one page of content
#   -X   keep content on screen after exit
#   -M   show more info at the bottom prompt line
#   -x4  tabs are 4 instead of 8
export LESS=-iRFXMx4

if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

if (( WSL )); then
  export DISPLAY=:0
  export WINDOWS_EDITOR='/mnt/c/Program Files/Notepad++/notepad++.exe'
  export WIN_TMPDIR=$(wslpath ${$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c "echo %TMP%")%$'\r'})
fi

eval $(dircolors -b)

(( WSL )) && local flavor=wsl || local flavor=linux
typeset -g MACHINE_ID=${(%):-%m}-${flavor}-${HOME:t}

[[ -f $HOME/.zshenv-private ]] && source $HOME/.zshenv-private

setopt NO_GLOBAL_RCS
