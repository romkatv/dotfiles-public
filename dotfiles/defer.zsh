case $(( init_stage++ )) in
  0)
    function reset-autosuggestions() { orig_buffer=; orig_postdisplay=; }
    zle -N reset-autosuggestions
    PROMPT='loading> '
    print -s nvm use v12.3.1
  ;;
  1)
    PROMPT='%~%# '
  ;;
  2)
    source ~/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ;;
  3)
    source ~/dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh
    _zsh_autosuggest_start
  ;;
  4)
    function nvm() {}
  ;;
  *)
    return
  ;;
esac

if zle; then
  zle reset-autosuggestions
  _ZSH_HIGHLIGHT_PRIOR_BUFFER=
  (( $+_zsh_highlight_main__command_type_cache )) && _zsh_highlight_main__command_type_cache=()
  zle reset-prompt
  zle -R
  zle redisplay
fi
zmodload zsh/sched
sched +1 source ~/.zshrc
