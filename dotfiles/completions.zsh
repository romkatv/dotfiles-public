zstyle ':completion:*'                    list-colors    "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:*'            menu           'select'
zstyle ':completion:*'                    matcher-list   'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*'                    special-dirs   'true'
zstyle ':completion:*:*:kill:*:processes' list-colors    '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes'    command        'ps -u $USER -o pid,user,comm -w -w'
zstyle ':completion::complete:*'          use-cache      '1'
zstyle '*'                                single-ignored 'show'

autoload -U compinit
compinit
