emulate zsh

ZSH=~/dotfiles/oh-my-zsh
ZSH_CUSTOM=$ZSH/custom

ZSH_AUTOSUGGEST_MANUAL_REBIND=1

if zmodload zsh/terminfo && (( terminfo[colors] >= 256 )); then
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'  # the default is hard to see
else
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=005'  # the default is outside of 8 color range
fi

[[ $TERM == xterm* ]] || : ${PURE_POWER_MODE:=portable}

source ~/dotfiles/functions.zsh

run-tracked     source $ZSH/plugins/command-not-found/command-not-found.plugin.zsh
# Kill binding and widget as we define our own in bindings.zsh. Strip random exports.
run-tracked -bwe source $ZSH/plugins/dirhistory/dirhistory.plugin.zsh
# Disallow `x` alias.
run-tracked -a  source $ZSH/plugins/extract/extract.plugin.zsh
# Allow `z` alias.
run-tracked +a  source $ZSH/plugins/z/z.plugin.zsh
run-tracked     source ~/dotfiles/zsh-prompt-benchmark/zsh-prompt-benchmark.plugin.zsh
run-tracked     source ~/dotfiles/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

functions[orig_zsh_autosuggest_bind_widgets]=$functions[_zsh_autosuggest_bind_widgets]
function _zsh_autosuggest_bind_widgets() {
  orig_zsh_autosuggest_bind_widgets
  _zsh_autosuggest_bind_widget zle-line-init modify
}

if [[ -d ~/gitstatus ]]; then
  GITSTATUS_ENABLE_LOGGING=1
  GITSTATUS_DAEMON=~/gitstatus/gitstatusd
  POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus
fi

if [[ -d ~/powerlevel10k ]]; then
  run-tracked source ~/powerlevel10k/powerlevel10k.zsh-theme
else
  run-tracked source ~/dotfiles/powerlevel10k/powerlevel10k.zsh-theme
fi

source ~/.purepower
source ~/dotfiles/history.zsh

[[ -f $HOME/.zshrc-private ]] && source $HOME/.zshrc-private

source ~/dotfiles/bindings.zsh
source ~/dotfiles/completions.zsh

# Must be sourced after all widgets have been defined. Rebinds all widgets.
run-tracked +w source ~/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

# Disable highlighting of text pasted into the command line.
zle_highlight=('paste:none')

# On every prompt, set terminal title to "user@host: cwd".
function set-term-title() { print -Pn '\e]0;%n@%m: %~\a' }
autoload -Uz add-zsh-hook
add-zsh-hook precmd set-term-title

(( $+aliases[run-help] )) && unalias run-help
autoload -Uz run-help

autoload -Uz zargs zmv zcp zln

source ~/dotfiles/aliases.zsh

ZLE_RPROMPT_INDENT=0           # don't leave an empty space after right prompt
READNULLCMD=$PAGER             # use the default pager instead of `more`
WORDCHARS=''                   # only alphanums make up words in word-based zle widgets
ZLE_REMOVE_SUFFIX_CHARS=''     # don't eat space when typing '|' after a tab completion

setopt ALWAYS_TO_END           # full completions move cursor to the end
setopt AUTO_CD                 # `dirname` is equivalent to `cd dirname`
setopt AUTO_PUSHD              # `cd` pushes directories to the directory stack
setopt EXTENDED_GLOB           # (#qx) glob qualifier and more
setopt GLOB_DOTS               # glob matches files starting with dot; `*` becomes `*(D)`
setopt HIST_EXPIRE_DUPS_FIRST  # if history needs to be trimmed, evict dups first
setopt HIST_IGNORE_DUPS        # don't add dups to history
setopt HIST_IGNORE_SPACE       # don't add commands starting with space to history
setopt HIST_REDUCE_BLANKS      # remove junk whitespace from commands before adding to history
setopt HIST_VERIFY             # if a cmd triggers history expansion, show it instead of running
setopt INTERACTIVE_COMMENTS    # allow comments in command line
setopt MULTIOS                 # allow multiple redirections for the same fd
setopt NO_BANG_HIST            # disable old history syntax
setopt NO_BG_NICE              # don't nice background jobs; not useful and doesn't work on WSL
setopt PROMPT_SUBST            # expand $FOO, $(bar) and the like in prompt
setopt PUSHD_IGNORE_DUPS       # don’t push copies of the same directory onto the directory stack
setopt PUSHD_MINUS             # `cd -3` now means "3 directory deeper in the stack"
setopt SHARE_HISTORY           # write and import history on every command
setopt EXTENDED_HISTORY        # write timestamps to history

# setopt COMPLETE_IN_WORD      # not sure what it does
# setopt NO_FLOW_CONTROL       # not sure what it does
