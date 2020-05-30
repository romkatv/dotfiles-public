[ -z "$-" -o -n "${-##*i*}" ] && setopt no_rcs && return

export XDG_CACHE_HOME="$HOME/.cache"
Z4H_URL="https://raw.githubusercontent.com/romkatv/zsh4humans/v3"
: "${Z4H:=${XDG_CACHE_HOME:-$HOME/.cache}/zsh4humans}"
[ -d ~/zsh4humans/main ] && Z4H_BOOTSTRAP_COMMAND='ln -s ~/zsh4humans/main "$Z4H_PACKAGE_DIR"'

umask o-w

if [ ! -e "$Z4H"/z4h.zsh ]; then
  mkdir -p -- "$Z4H" || return
  >&2 printf '\033[33mz4h\033[0m: fetching \033[4mz4h.zsh\033[0m\n'
  if [ -e ~/zsh4humans/main/z4h.zsh ]; then
    ln -s -- ~/zsh4humans/main/z4h.zsh "$Z4H"/z4h.zsh.$$ || return
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL -- "$Z4H_URL"/z4h.zsh >"$Z4H"/z4h.zsh.$$  || return
  else
    wget -O-   -- "$Z4H_URL"/z4h.zsh >"$Z4H"/z4h.zsh.$$  || return
  fi
  mv -- "$Z4H"/z4h.zsh.$$ "$Z4H"/z4h.zsh || return
fi

. "$Z4H"/z4h.zsh || return

zstyle ':z4h:'                          auto-update      ask
zstyle ':z4h:'                          auto-update-days 28
zstyle ':z4h:*'                         channel          testing
zstyle ':z4h:'                          cd-key           alt
zstyle ':z4h:autosuggestions'           forward-char     partial-accept

if [[ ${THEME:-1} == 0 ]]; then
  zstyle ':z4h:powerlevel10k'           channel none
elif [[ -d ~/powerlevel10k ]]; then
  zstyle ':z4h:powerlevel10k'           channel command 'ln -s -- ~/powerlevel10k $Z4H_PACKAGE_DIR'
fi

if [[ ${ZSYH:-1} == 0 ]]; then
  zstyle ':z4h:zsh-syntax-highlighting' channel none
fi

if [[ ${ZASUG:-1} == 0 ]]; then
  zstyle ':z4h:zsh-autosuggestions'     channel none
fi

if (( UID && UID == EUID && ! Z4H_SSH )); then
  z4h chsh
fi

z4h install romkatv/zsh-prompt-benchmark

z4h init || return

setopt glob_dots

ulimit -c $(((8 << 30) / 512))  # 8GB

path=(~/bin ~/.local/bin ~/.cargo/bin $path)
fpath+=(~/dotfiles/functions ~/dotfiles/archive)

autoload -Uz ${^${(M)fpath:#~/dotfiles/*}}/[^_]*(N:t) zmv is-at-least add-zsh-hook

export GPG_TTY=$TTY
export EDITOR=~/bin/redit
export PAGER=less
export GOPATH=$HOME/go
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export FZF_DEFAULT_COMMAND='rg --files --hidden'

if [[ "$(</proc/version)" == *Microsoft* ]] 2>/dev/null; then
  export WSL=1
  export DISPLAY=:0
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  sudo /usr/local/bin/clean-tmp-su
  z4h source ~/dotfiles/ssh-agent.zsh
  HISTFILE=~/.zsh_history.${(%):-%m}-wsl-${HOME:t}
  () {
    local lines=("${(@f)${$(/mnt/c/Windows/System32/cmd.exe /c set)//$'\r'}}")
    local keys=(${lines%%=*}) vals=(${lines#*=})
    typeset -gA wenv=(${keys:^vals})
    local home=$wenv[USERPROFILE]
    home=/mnt/${(L)home[1]}/${${home:3}//\\//}
    [[ -d $home ]] && hash -d h=$home
  }
  if [[ -x '/mnt/c/Program Files/Notepad++/notepad++.exe' ]]; then
    alias np="'/mnt/c/Program Files/Notepad++/notepad++.exe'"
  fi
else
  export WSL=0
  HISTFILE=~/.zsh_history.${(%):-%m}-linux-${HOME:t}
fi

() {
  emulate -L zsh
  setopt extended_glob
  local hist
  for hist in ~/.zsh_history*~$HISTFILE(N); do
    fc -RI $hist
  done
}

is-at-least 5.8 && ZLE_RPROMPT_INDENT=0
TIMEFMT='user=%U system=%S cpu=%P total=%*E'

function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

function bench() {
  emulate -L zsh
  if (( ! $+functions[zsh-prompt-benchmark] )); then
    z4h source $Z4H/romkatv/zsh-prompt-benchmark || return
  fi
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

function prompt_git_dir() {
  emulate -L zsh
  [[ -n $GIT_DIR ]] || return
  local repo=${GIT_DIR:t}
  [[ $repo == .git ]] && repo=${GIT_DIR:h:t}
  [[ $repo == .dotfiles-(public|private) ]] && repo=${repo#.dotfiles-}
  p10k segment -b 0 -f 208 -t ${repo//\%/%%}
}

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

(( $+POWERLEVEL9K_LEFT_PROMPT_ELEMENTS )) && p10k-on-init

if [[ -e ~/gitstatus/gitstatus.plugin.zsh ]]; then
  : ${GITSTATUS_LOG_LEVEL=DEBUG}
  : ${POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus}
fi

function toggle-dotfiles() {
  case "${GIT_DIR-}" in
    '')
      export GIT_DIR=~/.dotfiles-public
      export GIT_WORK_TREE=~
    ;;
    ~/.dotfiles-public)
      export GIT_DIR=~/.dotfiles-private
      export GIT_WORK_TREE=~
    ;;
    *)
      unset GIT_DIR
      unset GIT_WORK_TREE
    ;;
  esac
  local f
  for f in precmd "${precmd_functions[@]}"; do
    [[ "${+functions[$f]}" == 0 ]] || "$f" &>/dev/null || true
  done
  zle .reset-prompt
  zle -R
}

zle -N toggle-dotfiles

bindkey '^H' backward-kill-word
bindkey '^P' toggle-dotfiles

zstyle ':completion:*'                           sort               false
zstyle ':zle:(up|down)-line-or-beginning-search' leave-cursor       no
zstyle ':fzf-tab:*'                              continuous-trigger tab

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

alias ls="${aliases[ls]:-ls} -A"
if [[ -n $commands[dircolors] && ${${:-ls}:c:A:t} != busybox* ]]; then
  alias ls="${aliases[ls]:-ls} --group-directories-first"
fi

(( $+commands[tree]  )) && alias tree='tree -aC -I .git --dirsfirst'
(( $+commands[gedit] )) && alias gedit='gedit &>/dev/null'

if (( $+commands[xclip] )); then
  alias x='xclip -selection clipboard -in'
  alias v='xclip -selection clipboard -out'
  alias c='xclip -selection clipboard -in -filter'
fi

z4h source ~/.zshrc-private
