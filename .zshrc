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

if [[ ${P10K:-1} == 0 ]]; then
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

z4h install romkatv/archive romkatv/zsh-prompt-benchmark

z4h init || return

setopt glob_dots

ulimit -c $(((4 << 30) / 512))  # 4GB

[[ -d ~/.cargo/bin ]] && path=(~/.cargo/bin $path)
[[ -d ~/.local/bin ]] && path=(~/.local/bin $path)
[[ -d ~/bin        ]] && path=(~/bin $path)

fpath=($Z4H/romkatv/archive $fpath)
[[ -d ~/dotfiles/functions ]] && fpath=(~/dotfiles/functions $fpath)

autoload -Uz -- zmv is-at-least add-zsh-hook archive unarchive ~/dotfiles/functions/[^_]*(N:t)

if [[ -x ~/bin/redit ]]; then
  export VISUAL=~/bin/redit
else
  export VISUAL=${commands[nano]:-vi}
fi

export EDITOR=$VISUAL
export GPG_TTY=$TTY
export PAGER=less
export GOPATH=$HOME/go
export DOTNET_CLI_TELEMETRY_OPTOUT=1

if [[ -n $WSL_DISTRO_NAME ]]; then
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  [[ -z $SSH_CONNECTON && $P9K_SSH != 1 && -z $DISPLAY ]] && export DISPLAY=localhost:0.0
  z4h source ~/dotfiles/ssh-agent.zsh
  HISTFILE=~/.zsh_history.${(%):-%m}-wsl-${HOME:t}
  () {
    local lines=("${(@f)${$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c set)//$'\r'}}")
    local keys=(${lines%%=*}) vals=(${lines#*=})
    typeset -grA wenv=(${keys:^vals})
    local home=$wenv[USERPROFILE]
    home=/mnt/${(L)home[1]}/${${home:3}//\\//}
    [[ -d $home ]] && hash -d h=$home
  }
  () {
    emulate -L zsh -o dot_glob -o null_glob
    [[ -n $SSH_CONNECTON || $P9K_SSH == 1 ]] && return
    local -i uptime_sec=${$(</proc/uptime)[1]}
    local files=(${TMPDIR:-/tmp}/*(as+$((uptime_sec+86400))))
    (( $#files )) || return
    sudo rm -rf -- $files
  }
  if [[ -x '/mnt/c/Program Files/Notepad++/notepad++.exe' ]]; then
    alias np="'/mnt/c/Program Files/Notepad++/notepad++.exe'"
  fi
else
  HISTFILE=~/.zsh_history.${(%):-%m}-linux-${HOME:t}
fi

() {
  emulate -L zsh
  setopt extended_glob
  local hist
  for hist in ~/.zsh_history*~$HISTFILE(N); do
    fc -RI $hist
  done
  [[ -e $HISTFILE ]] && fc -RI $HISTFILE
}

is-at-least 5.8 && ZLE_RPROMPT_INDENT=0
TIMEFMT='user=%U system=%S cpu=%P total=%*E'

function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

function ssh() { z4h ssh "$@" }

if [[ -e ~/gitstatus/gitstatus.plugin.zsh ]]; then
  : ${GITSTATUS_LOG_LEVEL=DEBUG}
  : ${POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus}
fi

() {
  local key keys=(
    "^A"   "^B"   "^D"   "^E"   "^F"   "^N"   "^O"   "^P"   "^Q"   "^S"   "^T"   "^W"   "^Y"
    "^X*"  "^X="  "^X?"  "^XC"  "^XG"  "^Xa"  "^Xc"  "^Xd"  "^Xe"  "^Xg"  "^Xh"  "^Xm"  "^Xn"
    "^Xr"  "^Xs"  "^Xt"  "^Xu"  "^X~"  "^[ "  "^[!"  "^['"  "^[,"  "^[-"  "^[."  "^[0"  "^[1"
    "^[2"  "^[3"  "^[4"  "^[5"  "^[6"  "^[7"  "^[8"  "^[9"  "^[<"  "^[>"  "^[?"  "^[A"  "^[B"
    "^[C"  "^[D"  "^[F"  "^[G"  "^[L"  "^[M"  "^[N"  "^[P"  "^[Q"  "^[S"  "^[T"  "^[U"  "^[W"
    "^[_"  "^[a"  "^[b"  "^[c"  "^[d"  "^[f"  "^[g"  "^[l"  "^[n"  "^[p"  "^[q"  "^[s"  "^[t"
    "^[u"  "^[w"  "^[y"  "^[z"  "^[|"  "^[~"  "^[^I" "^[^J" "^[^L" "^[^_" "^[\"" "^[\$" "^X^B"
    "^X^F" "^X^J" "^X^K" "^X^N" "^X^O" "^X^R" "^X^U" "^X^X" "^[^D" "^[^G" "^[^H")
  for key in $keys; do
    bindkey $key z4h-do-nothing
  done
}

bindkey '^H' z4h-backward-kill-word

if (( $+functions[toggle-dotfiles] )); then
  zle -N toggle-dotfiles
  bindkey '^P' toggle-dotfiles
fi

zstyle ':completion:*'                           sort               false
zstyle ':completion:*:ls:*'                      list-dirs-first    true
zstyle ':zle:(up|down)-line-or-beginning-search' leave-cursor       no
zstyle ':fzf-tab:*'                              continuous-trigger tab

alias ls="${aliases[ls]:-ls} -A"
if [[ -n $commands[dircolors] && ${${:-ls}:c:A:t} != busybox* ]]; then
  alias ls="${aliases[ls]:-ls} --group-directories-first"
fi

(( $+commands[tree]  )) && alias tree='tree -aC -I .git --dirsfirst'
(( $+commands[gedit] )) && alias gedit='gedit &>/dev/null'
(( $+commands[rsync] )) && alias rsync='rsync -z'

if (( $+commands[xclip] && $#DISPLAY )); then
  alias x='xclip -selection clipboard -in'
  alias v='xclip -selection clipboard -out'
  alias c='xclip -selection clipboard -in -filter'
fi

[[ ! -e ~/.zshrc-private ]] || source ~/.zshrc-private
return 0
