umask 0002
ulimit -c unlimited

export WSL=$(grep -q Microsoft /proc/version && echo 1 || echo 0)
export PATH=$HOME/bin:${PATH#$HOME/bin:}
export EDITOR=$HOME/bin/redit
export PAGER=less
export GOPATH=$HOME/go

# This affects every invocation of `less`.
#
#   -R   color
#   -F   exit if there is less than one page of content
#   -X   keep content on screen after exit
#   -M   show more info at the bottom prompt line
#   -x4  tabs are 4 instead of 8
export LESS=-RFXMx4

if (( WSL )); then
  export DISPLAY=:0
  export WINDOWS_EDITOR='/mnt/c/Program Files/Notepad++/notepad++.exe'
  export WIN_TMPDIR=$(wslpath ${$(/mnt/c/Windows/System32/cmd.exe /c "echo %TMP%")%$'\r'})
fi

eval $(dircolors -b)

(( WSL )) && local flavor=wsl || local flavor=linux
typeset -g MACHINE_ID=${(%):-%m-$flavor-%n}

[[ -f $HOME/.zshenv-private ]] && source $HOME/.zshenv-private
