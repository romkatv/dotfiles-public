if (( WSL )); then
  typeset -g HISTFILE=~/.zsh_history.${(%):-%m}-wsl-${HOME:t}
else
  typeset -g HISTFILE=~/.zsh_history.${(%):-%m}-linux-${HOME:t}
fi

typeset -gi HISTSIZE=1000000000
typeset -gi SAVEHIST=1000000000
typeset -gi HISTFILESIZE=1000000000

() {
  emulate -L zsh
  setopt extended_glob
  local hist
  for hist in ~/.zsh_history*~$HISTFILE(N); do
    fc -RI $hist
  done
}
