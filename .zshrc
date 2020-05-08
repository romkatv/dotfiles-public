emulate zsh

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -gaU cdpath fpath mailpath path
path=($HOME/bin $HOME/.local/bin $HOME/.cargo/bin $path)

fpath+=~/dotfiles/functions
[[ -d ~/archive ]] && fpath+=~/archive || fpath+=~/dotfiles/archive
autoload -Uz ${^${(M)fpath:#~/*}}/[^_]*(N:t) zmv zcp zln is-at-least add-zsh-hook
autoload -Uz ${^fpath}/run-help-*(N:t)

if (( BENCH )); then
  print -rn -- $'\e]0;BENCH\a' >$TTY
else
  function set-term-title-precmd() {
    emulate -L zsh
    print -rn -- $'\e]0;'${(V%):-'%~'}$'\a' >$TTY
  }
  function set-term-title-preexec() {
    emulate -L zsh
    print -rn -- $'\e]0;'${(V)1}$'\a' >$TTY
  }
  add-zsh-hook preexec set-term-title-preexec
  add-zsh-hook precmd set-term-title-precmd
  set-term-title-precmd
fi

if [[ -x /usr/lib/command-not-found ]]; then
  function command_not_found_handler() { /usr/lib/command-not-found -- "$@" }
fi

function jit() {
  emulate -L zsh
  [[ $1.zwc -nt $1 || ! -w ${1:h} ]] && return
  zmodload -F zsh/files b:zf_mv b:zf_rm
  local tmp=$1.tmp.$$.zwc
  {
    zcompile -R -- $tmp $1 && zf_mv -f -- $tmp $1.zwc || return
  } always {
    (( $? )) && zf_rm -f -- $tmp
  }
}

function jit-source() {
  emulate -L zsh
  [[ -e $1 ]] && jit $1 && source -- $1
}

umask 0022
ulimit -c $(((8 << 30) / 512))  # 8GB

jit ~/.zshrc
jit ~/.zshenv

if [[ "$(</proc/version)" == *Microsoft* ]] 2>/dev/null; then
  export WSL=1
  export DISPLAY=:0
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  sudo /usr/local/bin/clean-tmp-su
else
  export WSL=0
fi

export EDITOR=~/bin/redit
export PAGER=less
export GOPATH=$HOME/go
export DOTNET_CLI_TELEMETRY_OPTOUT=1

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

if zmodload zsh/terminfo && (( terminfo[colors] >= 256 )); then
  # The default is hard to see.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
  typeset -A ZSH_HIGHLIGHT_STYLES=(comment fg=96)
else
  # The default is outside of 8 color range.
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=black,bold'
fi

path+=~/dotfiles/fzf/bin
FZF_COMPLETION_TRIGGER=
export FZF_DEFAULT_COMMAND='rg --files --hidden'

ZSH_HIGHLIGHT_MAXLENGTH=1024
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

if is-at-least 5.7.2 || [[ $ZSH_PATCHLEVEL =~ '^zsh-5\.7\.1-([0-9]+)-' && $match[1] -ge 50 ]]; then
  ZLE_RPROMPT_INDENT=0         # don't leave an empty space after right prompt
fi

TIMEFMT='user=%U system=%S cpu=%P total=%*E' # more concise output of `time`
PROMPT_EOL_MARK='%K{red} %k'   # mark the missing \n at the end of a comand output with a red block
READNULLCMD=$PAGER             # use the default pager instead of `more`
WORDCHARS=''                   # only alphanums make up words in word-based zle widgets
ZLE_REMOVE_SUFFIX_CHARS=''     # don't eat space when typing '|' after a tab completion

if [[ -d ~/zsh-defer ]]; then
  jit-source ~/zsh-defer/zsh-defer.plugin.zsh
else
  jit-source ~/dotfiles/zsh-defer/zsh-defer.plugin.zsh
fi

function prompt_git_dir() {
  emulate -L zsh
  [[ -n $GIT_DIR ]] || return
  local repo=${GIT_DIR:t}
  [[ $repo == .git ]] && repo=${GIT_DIR:h:t}
  [[ $repo == .dotfiles-(public|private) ]] && repo=${repo#.dotfiles-}
  p10k segment -b 0 -f 208 -t ${repo//\%/%%}
}

if (( ${THEME:-1} )); then
  if zmodload zsh/terminfo && (( terminfo[colors] >= 256 )); then
    jit-source ~/.p10k.zsh
  else
    jit-source ~/.p10k-portable.zsh
  fi
  function p10k-on-init() {
    emulate -L zsh
    (( POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[(I)git_dir] )) && return
    local -i vcs=POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[(I)vcs]
    (( vcs )) || return
    unset POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN
    POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[vcs,vcs-1]=(git_dir)
    [[ -e ~/gitstatus/gitstatus.plugin.zsh ]] && : ${POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus}
    (( $+functions[p10k] )) && p10k reload
  }
  p10k-on-init
  if [[ -d ~/powerlevel10k ]]; then
    jit-source ~/powerlevel10k/powerlevel10k.zsh-theme
  else
    jit-source ~/dotfiles/powerlevel10k/powerlevel10k.zsh-theme
  fi
fi

if [[ -e ~/gitstatus/gitstatus.plugin.zsh ]]; then
  : ${GITSTATUS_LOG_LEVEL=DEBUG}
  : ${POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus}
  [[ -e ~/gitstatus/usrbin/gitstatusd ]] && : ${GITSTATUS_DAEMON=~/gitstatus/usrbin/gitstatusd}
fi

jit-source ~/dotfiles/completions.zsh
jit-source ~/dotfiles/bindings.zsh
jit-source ~/dotfiles/history.zsh
(( WSL )) && jit-source ~/dotfiles/ssh-agent.zsh

# Disable highlighting of text pasted into the command line.
zle_highlight=('paste:none')

jit-source ~/dotfiles/aliases.zsh

if (( BENCH )); then
  if [[ -d ~/zsh-prompt-benchmark ]]; then
    jit-source ~/zsh-prompt-benchmark/zsh-prompt-benchmark.plugin.zsh
  else
    jit-source ~/dotfiles/zsh-prompt-benchmark/zsh-prompt-benchmark.plugin.zsh
  fi
  function bench() {
    emulate -L zsh
    local on_done
    if (( $+commands[gsettings] )); then
      gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 1 || return
      on_done=_bench_restore_key_repeat_interval
      function _bench_restore_key_repeat_interval() {
        gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
      }
    fi
    zsh-prompt-benchmark ${1:-2} ${2:-2} $on_done
  }
else
  jit-source ~/dotfiles/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fi

# export PYENV_ROOT=~/.pyenv
# path=("$PYENV_ROOT/bin" $path)
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"

# export RBENV_ROOT=~/.rbenv
# path=($HOME/.rbenv/bin $path)
# eval "$(rbenv init -)"

# export LUAENV_ROOT=~/.luaenv
# path=($HOME/.luaenv/bin $path)
# eval "$(luaenv init -)"

# export JENV_ROOT=~/.jenv
# path=($HOME/.jenv/bin $path)
# eval "$(jenv init -)"

# export PLENV_ROOT=~/.plenv
# path=($HOME/.plenv/bin $path)
# eval "$(plenv init -)"

# export GOENV_ROOT=~/.goenv
# path=($HOME/.goenv/bin $path)
# eval "$(goenv init -)"
# [[ -n $GOROOT ]] && path=($GOROOT/bin $path)
# [[ -n $GOPATH ]] && path=($path $GOPATH/bin)

# path=($HOME/.nodenv/bin $path)
# eval "$(nodenv init -)"

# source ~/.asdf/asdf.sh
# source ~/.asdf/completions/asdf.bash

# path+=(/usr/lib/dart/bin ~/.pub-cache/bin)

# path=($HOME/.ebcli-virtual-env/executables $HOME/.pyenv/versions/3.7.2/bin $path)

# eval "$(direnv hook zsh)"

jit-source ~/.zshrc-private

# Must be sourced after all widgets have been defined.
(( BENCH )) || jit-source ~/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh

emulate zsh
setopt ALWAYS_TO_END           # full completions move cursor to the end
setopt AUTO_CD                 # `dirname` is equivalent to `cd dirname`
setopt AUTO_PARAM_SLASH        # if completed parameter is a directory, add a trailing slash
setopt AUTO_PUSHD              # `cd` pushes directories to the directory stack
setopt COMPLETE_IN_WORD        # complete from the cursor rather than from the end of the word
setopt EXTENDED_GLOB           # (#qx) glob qualifier and more
setopt EXTENDED_HISTORY        # write timestamps to history
setopt GLOB_DOTS               # glob matches files starting with dot; `*` becomes `*(D)`
setopt HIST_EXPIRE_DUPS_FIRST  # if history needs to be trimmed, evict dups first
setopt HIST_FIND_NO_DUPS       # don't show dups when searching history
setopt HIST_IGNORE_DUPS        # don't add dups to history
setopt HIST_IGNORE_SPACE       # don't add commands starting with space to history
setopt HIST_VERIFY             # if a command triggers history expansion, show it instead of running
setopt INTERACTIVE_COMMENTS    # allow comments in command line
setopt MULTIOS                 # allow multiple redirections for the same fd
setopt NO_BANG_HIST            # disable old history syntax
setopt NO_BG_NICE              # don't nice background jobs; not useful and doesn't work on WSL
setopt NO_FLOW_CONTROL         # disable start/stop characters in shell editor
setopt PATH_DIRS               # perform path search even on command names with slashes
setopt SHARE_HISTORY           # write and import history on every command
setopt C_BASES                 # print hex/oct numbers as 0xFF/077 instead of 16#FF/8#77
