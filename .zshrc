emulate zsh

autoload -Uz add-zsh-hook run-help zargs zmv zcp zln is-at-least

ZSH=~/dotfiles/oh-my-zsh
ZSH_CUSTOM=$ZSH/custom

ZSH_HIGHLIGHT_MAXLENGTH=1024
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

if zmodload zsh/terminfo && (( terminfo[colors] >= 256 )); then
  # The default is hard to see.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
  typeset -A ZSH_HIGHLIGHT_STYLES=(comment fg=96)
else
  # The default is outside of 8 color range.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=5'
fi

source ~/dotfiles/functions.zsh

path+=~/dotfiles/fzf/bin
FZF_COMPLETION_TRIGGER=
export FZF_DEFAULT_COMMAND='rg --files --hidden'

[[ -r /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found

# Disallow `x` alias.
run-tracked -a source $ZSH/plugins/extract/extract.plugin.zsh
run-tracked    source ~/dotfiles/zsh-prompt-benchmark/zsh-prompt-benchmark.plugin.zsh

function late-init() {
  emulate -L zsh

  # Must be sourced after all widgets have been defined but before zsh-autosuggestions.
  run-tracked +w source ~/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

  run-tracked    source ~/dotfiles/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
  run-tracked +w _zsh_autosuggest_start
  
  add-zsh-hook -d precmd late-init
  unfunction late-init
}
add-zsh-hook precmd late-init

if (( ${THEME:-1} )); then
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
  if [[ -d ~/powerlevel10k ]]; then
    run-tracked +e source ~/powerlevel10k/powerlevel10k.zsh-theme
  else
    run-tracked +e source ~/dotfiles/powerlevel10k/powerlevel10k.zsh-theme
  fi
fi

if [[ -d ~/gitstatus ]]; then
  GITSTATUS_LOG_LEVEL=DEBUG
  POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus
  [[ -f ~/gitstatus/gitstatusd ]] && GITSTATUS_DAEMON=~/gitstatus/gitstatusd
fi

source ~/dotfiles/history.zsh
source ~/dotfiles/bindings.zsh
source ~/dotfiles/completions.zsh

# Disable highlighting of text pasted into the command line.
zle_highlight=('paste:none')

# On every prompt, set terminal title to "user@host: cwd".
function set-term-title() { print -Pn '\e]0;%n@%m: %~\a' }
add-zsh-hook precmd set-term-title

(( $+aliases[run-help] )) && unalias run-help
source ~/dotfiles/aliases.zsh

if is-at-least 5.7.2 || [[ $ZSH_PATCHLEVEL =~ '^zsh-5\.7\.1-([0-9]+)-' && $match[1] -ge 50 ]]; then
  ZLE_RPROMPT_INDENT=0         # don't leave an empty space after right prompt
fi

READNULLCMD=$PAGER             # use the default pager instead of `more`
WORDCHARS=''                   # only alphanums make up words in word-based zle widgets
ZLE_REMOVE_SUFFIX_CHARS=''     # don't eat space when typing '|' after a tab completion

setopt ALWAYS_TO_END           # full completions move cursor to the end
setopt AUTO_CD                 # `dirname` is equivalent to `cd dirname`
setopt AUTO_LIST               # automatically list choices on ambiguous completion
setopt AUTO_MENU               # show completion menu on a successive tab press
setopt AUTO_PARAM_SLASH        # if completed parameter is a directory, add a trailing slash
setopt AUTO_PUSHD              # `cd` pushes directories to the directory stack
setopt COMPLETE_IN_WORD        # complete from both ends of a word
setopt EXTENDED_GLOB           # needed for file modification glob modifiers with compinit
setopt EXTENDED_GLOB           # (#qx) glob qualifier and more
setopt EXTENDED_HISTORY        # write timestamps to history
setopt GLOB_DOTS               # glob matches files starting with dot; `*` becomes `*(D)`
setopt HIST_EXPIRE_DUPS_FIRST  # if history needs to be trimmed, evict dups first
setopt HIST_FIND_NO_DUPS       # don't show dups when searching history
setopt HIST_IGNORE_DUPS        # don't add dups to history
setopt HIST_IGNORE_SPACE       # don't add commands starting with space to history
setopt HIST_REDUCE_BLANKS      # remove junk whitespace from commands before adding to history
setopt HIST_VERIFY             # if a cmd triggers history expansion, show it instead of running
setopt INTERACTIVE_COMMENTS    # allow comments in command line
setopt MULTIOS                 # allow multiple redirections for the same fd
setopt NO_BANG_HIST            # disable old history syntax
setopt NO_BG_NICE              # don't nice background jobs; not useful and doesn't work on WSL
setopt NO_FLOW_CONTROL         # disable start/stop characters in shell editor
setopt NO_MENU_COMPLETE        # do not autoselect the first completion entry
setopt PATH_DIRS               # perform path search even on command names with slashes
setopt SHARE_HISTORY           # write and import history on every command

# export PYENV_ROOT="$HOME/.pyenv"
# path=("$PYENV_ROOT/bin" $path)
# eval "$(pyenv init -)"

# path=($HOME/.rbenv/bin $path)
# eval "$(rbenv init -)"

# path=($HOME/.nodenv/bin $path)
# eval "$(nodenv init -)"

[[ -f $HOME/.zshrc-private ]] && source $HOME/.zshrc-private
