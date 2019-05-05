typeset -g  HISTFILE=~/.zsh_history${MACHINE_ID:+.${MACHINE_ID}}
typeset -gi HISTSIZE=1000000000
typeset -gi SAVEHIST=1000000000
typeset -gi HISTFILESIZE=1000000000

() {
  emulate -L zsh && setopt NULL_GLOB
  local hist
  for hist in ~/.zsh_history*; do
    [[ $hist == $HISTFILE ]] || fc -RI $hist
  done
}
