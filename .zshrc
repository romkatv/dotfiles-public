zstyle ':z4h:'                auto-update      ask
zstyle ':z4h:'                auto-update-days 28
zstyle ':z4h:*'               channel          testing
zstyle ':z4h:'                cd-key           alt
zstyle ':z4h:autosuggestions' forward-char     partial-accept

() {
  local var proj
  for var proj in P10K powerlevel10k ZSYH zsh-syntax-highlighting ZASUG zsh-autosuggestions; do
    if [[ ${(P)var} == 0 ]]; then
      zstyle ":z4h:$proj" channel none
    elif [[ -d ~/$proj ]]; then
      zstyle ":z4h:$proj" channel command "ln -s -- ~/$proj \$Z4H_PACKAGE_DIR"
    fi
  done
}

z4h install romkatv/archive romkatv/zsh-prompt-benchmark

[[ -e ~/.ssh/id_rsa ]] || : ${GITSTATUS_AUTO_INSTALL:=0}

z4h init || return

setopt glob_dots

ulimit -c $(((4 << 30) / 512))  # 4GB

fpath=($Z4H/romkatv/archive $fpath)
[[ -d ~/dotfiles/functions ]] && fpath=(~/dotfiles/functions $fpath)

autoload -Uz -- zmv archive unarchive ~/dotfiles/functions/[^_]*(N:t)

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

if [[ "$(</proc/version)" == *[Mm]icrosoft* ]] 2>/dev/null; then
  export NO_AT_BRIDGE=1
  export LIBGL_ALWAYS_INDIRECT=1
  [[ -z $SSH_CONNECTON && -z $P9K_SSH && -z $DISPLAY ]] && export DISPLAY=localhost:0.0
  z4h source ~/dotfiles/ssh-agent.zsh
  () {
    local lines=("${(@f)${$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c set)//$'\r'}}")
    local keys=(${lines%%=*}) vals=(${lines#*=})
    typeset -grA wenv=(${keys:^vals})
    local home=$wenv[USERPROFILE]
    home=/mnt/${(L)home[1]}/${${home:3}//\\//}
    [[ -d $home ]] && hash -d w=$home
  }
  () {
    emulate -L zsh -o dot_glob -o null_glob
    [[ -n $SSH_CONNECTON || -n $P9K_SSH ]] && return
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

TIMEFMT='user=%U system=%S cpu=%P total=%*E'

function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

function ssh() { z4h ssh "$@" }

zstyle    ':z4h:ssh:*' ssh-command      command ssh
zstyle    ':z4h:ssh:*' send-extra-files '~/.zshrc-private' '~/bin/slurp' '~/bin/barf'
zstyle -e ':z4h:ssh:*' retrieve-history 'reply=($ZDOTDIR/.zsh_history.${(%):-%m}:$z4h_ssh_host)'

function z4h-ssh-configure() {
  local file
  for file in $ZDOTDIR/.zsh_history.*:$z4h_ssh_host(N); do
    (( $+z4h_ssh_send_files[$file] )) && continue
    z4h_ssh_send_files[$file]='"$ZDOTDIR"/'${file:t}
  done
}

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

zstyle ':completion:*'                            sort               false
zstyle ':completion:*:ls:*'                       list-dirs-first    true
zstyle ':completion:*:-tilde-:*'                  tag-order          named-directories users
zstyle ':completion::complete:ssh:argument-1:'    tag-order          hosts users
zstyle ':completion::complete:scp:argument-rest:' tag-order          hosts files users
zstyle ':completion:complete:ssh:argument-1'      sort               true
zstyle ':completion:complete:scp:argument-rest'   sort               true
zstyle ':completion::complete:(ssh|scp):*:hosts'  hosts
zstyle ':fzf-tab:*'                               continuous-trigger tab
zstyle ':zle:(up|down)-line-or-beginning-search'  leave-cursor       no

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
  function copy-buffer-to-clipboard() {
    print -rn -- "$PREBUFFER$BUFFER" | xclip -selection clipboard -in
  }
  zle -N copy-buffer-to-clipboard
  bindkey '^S' copy-buffer-to-clipboard
fi

if [[ -n $commands[make] && -x ~/bin/num-cpus ]]; then
  alias make='make -j "${_my_num_cpus:-${_my_num_cpus::=$(~/bin/num-cpus)}}"'
fi

z4h source ~/.zshrc-private
return 0
