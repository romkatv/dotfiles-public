emulate zsh

typeset -g WORDCHARS=''                 # only alphanums make up words in word-based zle widgets
typeset -g ZLE_REMOVE_SUFFIX_CHARS=''   # don't eat space when typing '|' after a tab completion

typeset -g HISTFILE=$HOME/.zsh_history
typeset -g HISTSIZE=1000000000
typeset -g SAVEHIST=1000000000
typeset -g HISTFILESIZE=1000000000

typeset -g ZSH=~/dotfiles/oh-my-zsh
typeset -g ZSH_CUSTOM=$ZSH/custom

typeset -g ZSH_AUTOSUGGEST_MANUAL_REBIND=1
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'  # the default is hard to see

source ~/dotfiles/functions.zsh
source ~/dotfiles/bindings.zsh
source ~/dotfiles/completions.zsh
source ~/dotfiles/aliases.zsh
source ~/.purepower

[[ -f $HOME/.zshrc-private ]] && source $HOME/.zshrc-private

run-tracked -v    source $ZSH/plugins/command-not-found/command-not-found.plugin.zsh
# Disallow binding changes. We bind dirhistory_zle_dirhistory_up and others explicitly.
run-tracked -v -b source $ZSH/plugins/dirhistory/dirhistory.plugin.zsh
# Disallow `x` alias.
run-tracked -v -a source $ZSH/plugins/extract/extract.plugin.zsh
# Allow `z` alias.
run-tracked -v +a source $ZSH/plugins/z/z.plugin.zsh
run-tracked -v    source ~/dotfiles/zsh-prompt-benchmark/zsh-prompt-benchmark.plugin.zsh
run-tracked -v    source ~/dotfiles/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

if [[ -d ~/powerlevel10k && -d ~/gitstatus ]]; then
  typeset -g GITSTATUS_ENABLE_LOGGING=1
  typeset -g GITSTATUS_DAEMON=~/gitstatus/gitstatusd
  typeset -g POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus
  run-tracked -v source ~/powerlevel10k/powerlevel10k.zsh-theme
else
  run-tracked -v source ~/dotfiles/powerlevel10k/powerlevel10k.zsh-theme
fi

# Must be sourced after all widgets have been defined.
run-tracked -v source ~/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

# On every prompt, set terminal title to "user@host: cwd".
function set-term-title() { print -Pn '\e]0;%n@%m: %~\a' }
autoload -U add-zsh-hook
add-zsh-hook precmd set-term-title

autoload -Uz zargs zmv zcp zln

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
