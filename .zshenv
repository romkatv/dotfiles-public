export WSL=$(grep -q Microsoft /proc/version && echo 1 || echo 0)
export PATH=$PATH:/usr/local/cuda/bin:$HOME/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
export EDITOR=$HOME/bin/redit
export GOPATH=$HOME/go

if [[ "$WSL" == 1 ]]; then
  export DISPLAY=:0
fi

ulimit -c unlimited
