umask 0002
ulimit -c unlimited

if [[ -r /proc/version && "$(</proc/version)" == *Microsoft* ]]; then
  export WSL=1
else
  export WSL=0
fi
export EDITOR=$HOME/bin/redit
export PAGER=less
export GOPATH=$HOME/go
export DOTNET_CLI_TELEMETRY_OPTOUT=1

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
  export LIBGL_ALWAYS_INDIRECT=1
fi

if (( $+commands[dircolors] )); then
  eval "$(command dircolors -b)"
fi

typeset -g MACHINE_ID=${(%):-%m}-${${${WSL:#0}:+wsl}:-linux}-${HOME:t}

setopt NO_GLOBAL_RCS

[[ -r ~/.zshenv-private ]] && source $HOME/.zshenv-private || true
