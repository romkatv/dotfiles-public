HISTFILE=~/.zsh_history${MACHINE_ID:+.${MACHINE_ID}}
HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILESIZE=1000000000

() {
  local hist
  for hist in ~/.zsh_history*(N); do
    [[ $hist == $HISTFILE ]] || fc -RI $hist
  done
}
