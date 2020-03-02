# Based on:
# https://github.com/sorin-ionescu/prezto/blob/6f603df7a641fb136b8b168d75e905fef60a00cf/modules/completion/init.zsh.
#
# Which is released under MIT license:
# https://github.com/sorin-ionescu/prezto/blob/6f603df7a641fb136b8b168d75e905fef60a00cf/LICENSE.

autoload -Uz compinit
compinit -d ${XDG_CACHE_HOME:-~/.cache}/.zcompdump-$ZSH_VERSION
jit ${XDG_CACHE_HOME:-~/.cache}/.zcompdump-$ZSH_VERSION

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'l:|=* r:|=*'

zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/.zcompcache-$ZSH_VERSION
zstyle ':completion:*:descriptions' format '[%d]'
#zstyle ':completion:*' completer _complete
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' single-ignored show
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'
zstyle ':completion:*:*:*:*:processes' command 'ps -A -o pid,user,command -w'

zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2> /dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts(|)(N) <<(${commands[ypcat]:-true} hosts 2> /dev/null))"}%%\#*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2> /dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
