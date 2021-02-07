zstyle ':z4h:'                  auto-update        no
zstyle ':z4h:'                  auto-update-days   28
zstyle ':z4h:*'                 channel            testing
zstyle ':z4h:autosuggestions'   forward-char       partial-accept
zstyle ':z4h:autosuggestions'   end-of-line        partial-accept
zstyle ':z4h:term-title:ssh'    precmd             ${${${Z4H_SSH##*:}//\%/%%}:-%m}': %~'
zstyle ':z4h:term-title:ssh'    preexec            ${${${Z4H_SSH##*:}//\%/%%}:-%m}': ${1//\%/%%}'
zstyle ':z4h:command-not-found' to-file            "$TTY"
zstyle ':z4h:'                  iterm2-integration yes

# zstyle :z4h: start-tmux no

() {
  local var proj
  for var proj in P10K powerlevel10k ZSYH zsh-syntax-highlighting ZASUG zsh-autosuggestions; do
    if [[ ${(P)var} == 0 ]]; then
      zstyle ":z4h:$proj" channel none
    elif [[ -d ~/$proj ]]; then
      zstyle ":z4h:$proj" channel command "zf_ln -s -- ~/$proj \$Z4H_PACKAGE_DIR"
    fi
  done
}

z4h install romkatv/archive romkatv/zsh-prompt-benchmark

[[ -e ~/.ssh/id_rsa ]] || : ${GITSTATUS_AUTO_INSTALL:=0}

z4h init || return

setopt glob_dots magic_equal_subst no_multi_os no_local_loops
setopt rm_star_silent rc_quotes glob_star_short

ulimit -c $(((4 << 30) / 512))  # 4GB

fpath=($Z4H/romkatv/archive $fpath)
[[ -d ~/dotfiles/functions ]] && fpath=(~/dotfiles/functions $fpath)

autoload -Uz -- zmv archive lsarchive unarchive ~/dotfiles/functions/[^_]*(N:t)

if [[ -x ~/bin/redit ]]; then
  export VISUAL=~/bin/redit
else
  export VISUAL=${${commands[nano]:t}:-vi}
fi

export EDITOR=$VISUAL
export GPG_TTY=$TTY
export PAGER=less
export GOPATH=$HOME/go
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export HOMEBREW_NO_ANALYTICS=1

if (( $+z4h_win_env )); then
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  [[ -z $SSH_CONNECTON && $P9K_SSH != 1 && -z $DISPLAY ]] && export DISPLAY=localhost:0.0
  z4h source -c ~/dotfiles/ssh-agent.zsh
  (( $+z4h_win_home )) && hash -d w=$z4h_win_home
  () {
    emulate -L zsh -o dot_glob -o null_glob
    [[ -n $SSH_CONNECTON || $P9K_SSH == 1 ]] && return
    local -i uptime_sec=${$(</proc/uptime)[1]}
    local files=(${TMPDIR:-/tmp}/*(as+$((uptime_sec+86400))))
    (( $#files )) || return
    sudo rm -rf -- $files
  }
fi

() {
  local hist
  for hist in ~/.zsh_history*~$HISTFILE(N); do
    fc -RI $hist
  done
}

function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }

compdef _directories md
compdef _default     open

zstyle    ':z4h:ssh:*' enable           yes
zstyle    ':z4h:ssh:*' ssh-command      command ssh
zstyle    ':z4h:ssh:*' send-extra-files '~/.zshenv-private' '~/.zshrc-private' '~/.config/htop/htoprc'
zstyle -e ':z4h:ssh:*' retrieve-history 'reply=($ZDOTDIR/.zsh_history.${(%):-%m}:$z4h_ssh_host)'

function z4h-ssh-configure() {
  (( z4h_ssh_enable )) || return 0
  local file
  for file in $ZDOTDIR/.zsh_history.*:$z4h_ssh_host(N); do
    (( $+z4h_ssh_send_files[$file] )) && continue
    z4h_ssh_send_files[$file]='"$ZDOTDIR"/'${file:t}
  done
}

[[ -e ~/.ssh/control-master ]] || zf_mkdir -p -m 700 ~/.ssh/control-master

if [[ -e ~/gitstatus/gitstatus.plugin.zsh ]]; then
  : ${GITSTATUS_LOG_LEVEL=DEBUG}
  : ${POWERLEVEL9K_GITSTATUS_DIR=~/gitstatus}
fi

() {
  local key keys=(
    "^A"   "^B"   "^D"   "^E"   "^F"   "^N"   "^O"   "^P"   "^Q"   "^S"   "^T"   "^W"
    "^X*"  "^X="  "^X?"  "^XC"  "^XG"  "^Xa"  "^Xc"  "^Xd"  "^Xe"  "^Xg"  "^Xh"  "^Xm"  "^Xn"
    "^Xr"  "^Xs"  "^Xt"  "^Xu"  "^X~"  "^[ "  "^[!"  "^['"  "^[,"  "^[-"  "^[."  "^[0"  "^[1"
    "^[2"  "^[3"  "^[4"  "^[5"  "^[6"  "^[7"  "^[8"  "^[9"  "^[<"  "^[>"  "^[?"  "^[A"  "^[B"
    "^[C"  "^[D"  "^[F"  "^[G"  "^[L"  "^[M"  "^[N"  "^[P"  "^[Q"  "^[S"  "^[T"  "^[U"  "^[W"
    "^[_"  "^[a"  "^[b"  "^[c"  "^[d"  "^[f"  "^[g"  "^[l"  "^[n"  "^[p"  "^[q"  "^[s"  "^[t"
    "^[u"  "^[w"  "^[y"  "^[z"  "^[|"  "^[~"  "^[^I" "^[^J" "^[^_" "^[\"" "^[\$" "^X^B"
    "^X^F" "^X^J" "^X^K" "^X^N" "^X^O" "^X^R" "^X^U" "^X^X" "^[^D" "^[^G")
  for key in $keys; do
    bindkey $key z4h-do-nothing
  done
}

z4h bindkey z4h-backward-kill-word  Ctrl+Backspace
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace
z4h bindkey z4h-cd-back             Alt+Left
z4h bindkey z4h-cd-forward          Alt+Right
z4h bindkey z4h-cd-up               Alt+Up
z4h bindkey z4h-cd-down             Alt+Down

if (( $+functions[toggle-dotfiles] )); then
  zle -N toggle-dotfiles
  z4h bindkey toggle-dotfiles Ctrl+P
fi

zstyle ':z4h:fzf-complete'                   fzf-bindings       tab:repeat
zstyle ':z4h:cd-down'                        fzf-bindings       tab:repeat

zstyle ':zle:up-line-or-beginning-search'    leave-cursor       no
zstyle ':zle:down-line-or-beginning-search'  leave-cursor       no

zstyle ':completion:*'                       sort               false
zstyle ':completion:*:ls:*'                  list-dirs-first    true
zstyle ':completion:*:ssh:argument-1:'       tag-order          hosts users
zstyle ':completion:*:scp:argument-rest:'    tag-order          hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

alias ls="${aliases[ls]:-ls} -A"
if [[ -n $commands[dircolors] && ${${:-ls}:c:A:t} != busybox* ]]; then
  alias ls="${aliases[ls]:-ls} --group-directories-first"
fi

[[ ${${:-grep}:c:A:t} == busybox* ]] || alias grep='() {
  if [[ -t 1 ]]; then
    \grep --color=always --exclude-dir={.bzr,CVS,.git,.hg,.svn} "$@" | tr -d "\r"
  else
    \grep --exclude-dir={.bzr,CVS,.git,.hg,.svn} "$@"
  fi
}'

(( $+commands[tree]  )) && alias tree='tree -a -I .git --dirsfirst'
(( $+commands[gedit] )) && alias gedit='gedit &>/dev/null'
(( $+commands[rsync] )) && alias rsync='rsync -rz --info=FLIST,COPY,DEL,REMOVE,SKIP,SYMSAFE,MISC,NAME,PROGRESS,STATS'
(( $+commands[exa]   )) && alias exa='exa -ga --group-directories-first --time-style=long-iso --color-scale'

if (( $+commands[xclip] && $#DISPLAY )); then
  alias x='xclip -selection clipboard -in'
  alias v='xclip -selection clipboard -out'
  alias c='xclip -selection clipboard -in -filter'
  function copy-buffer-to-clipboard() {
    print -rn -- "$PREBUFFER$BUFFER" | xclip -selection clipboard -in
  }
  zle -N copy-buffer-to-clipboard
  bindkey '^S' copy-buffer-to-clipboard
fi

if [[ -x ~/bin/num-cpus ]]; then
  if (( $+commands[make] )); then
    alias make='make -j "${_my_num_cpus:-${_my_num_cpus::=$(~/bin/num-cpus)}}"'
  fi
  if (( $+commands[cmake] )); then
    alias cmake='cmake -j "${_my_num_cpus:-${_my_num_cpus::=$(~/bin/num-cpus)}}"'
  fi
fi

z4h source -c -- $ZDOTDIR/.zshrc-private
z4h compile -- $ZDOTDIR/{.zshenv,.zprofile,.zshrc,.zlogin,.zlogout}
