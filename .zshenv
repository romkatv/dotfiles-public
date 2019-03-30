export WSL=$(grep -q Microsoft /proc/version && echo 1 || echo 0)
export PATH=$HOME/bin:${PATH#$HOME/bin:}
export EDITOR=$HOME/bin/redit
export GOPATH=$HOME/go

if [[ $WSL == 1 ]]; then
  export DISPLAY=:0
  export WINDOWS_EDITOR='/mnt/c/Program Files/Notepad++/notepad++.exe'
  export WIN_TMPDIR=$(wslpath ${$(/mnt/c/Windows/System32/cmd.exe /c "echo %TMP%")%$'\r'})
fi

umask 0002
ulimit -c unlimited
