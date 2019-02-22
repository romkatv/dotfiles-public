export ZSH=$HOME/.oh-my-zsh

# See https://github.com/bhilburn/powerlevel9k for configuration options.
ZSH_THEME=powerlevel9k/powerlevel9k

POWERLEVEL9K_MODE=nerdfont-complete                   # use exotic symbols
POWERLEVEL9K_PROMPT_ON_NEWLINE=true                   # user commands on new line
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0       # always show execution time
POWERLEVEL9K_CUSTOM_RPROMPT=custom_rprompt            # user-defined custom_rprompt()
POWERLEVEL9K_ROOT_ICON=\\uF09C                        # unlocked lock icon
POWERLEVEL9K_TIME_BACKGROUND=magenta
POWERLEVEL9K_CUSTOM_RPROMPT_BACKGROUND=blue
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=grey
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=black
POWERLEVEL9K_STATUS_OK_BACKGROUND=grey37
POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=grey37

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  root_indicator # display an unlocked lock icon when root
  dir_writable   # display a locked lock icon when the current dir isn't writable
  dir            # current dir
  vcs            # git status if inside a git repo
)

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                  # status code of the last command
  command_execution_time  # execution time of the last command
  background_jobs         # the number of background jobs
  time                    # current time
  custom_rprompt          # the results of `custom_rprompt` (can be redefined by the user)
)

ZLE_REMOVE_SUFFIX_CHARS=''    # don't eat the space when typing '|' after a tab completion
ZSH_DISABLE_COMPFIX=true      # don't complain about permissions when completing
ENABLE_CORRECTION=true        # zsh: correct 'sl' to 'ls' [nyae]?
COMPLETION_WAITING_DOTS=true  # show "..." while completing

plugins=(
  git                      # not sure what it does
  zsh-syntax-highlighting  # not sure what it does
  zsh-autosuggestions      # suggests commands as you type, based on command history (grey text)
  command-not-found        # use ubuntu's command-not-found on unrecognized command
  dirhistory               # alt-left and alt-right to navigate dir history; alt-up for `cd ..`
  extract                  # `extract <archive>` command
)

source $ZSH/oh-my-zsh.sh

zle_highlight=(default:bold)  # bold prompt

alias clang-format='clang-format -style=file'
alias less='less --LONG-PROMPT --tabs=4'
alias ls='ls --group-directories-first --color=tty'
alias gedit='gedit &>/dev/null'

# If you want some random config file to be versioned in the dotfiles-public git repo, type
# `dotfiles-public add -f <random-file>`. Use `commit`, `push`, etc., as with normal git.
alias dotfiles-public='git --git-dir=$HOME/.dotfiles-public/.git --work-tree=$HOME'
alias dotfiles-private='git --git-dir=$HOME/.dotfiles-private/.git --work-tree=$HOME'

alias x='xsel --clipboard -i'  # cut to clipboard
alias v='xsel --clipboard -o'  # paste from clipboard
alias c='x && v'               # copy to clipboard

stty susp '^B'  # ctrl+b instead of ctrl+z to suspend

bindkey '^H'      backward-kill-word  # ctrl+backspace -- delete previous word
bindkey '^[[3;5~' kill-word           # ctrl+del       -- delete next word
bindkey '^J'      backward-kill-line  # ctrl+j         -- delete everything before cursor
bindkey '^Z'      undo                # ctrl+z         -- undo
bindkey '^Y'      redo                # ctrl+y         -- redo
bindkey '^P'      set-local-history   # ctrl+m         -- toggle between shared and local history

HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILESIZE=1000000000

setopt HIST_IGNORE_SPACE     # don't add commands starting with space to history
setopt HIST_VERIFY           # if a cmd triggers history expansion, show it instead of running
setopt HIST_IGNORE_ALL_DUPS  # duplicate commands evict older twins
setopt HIST_REDUCE_BLANKS    # remove junk whitespace from commands before adding to history
setopt EXTENDEDGLOB          # extended glob support: ^*.cc(.) for all regular files but *.cc
setopt NOEQUALS              # disable =foo being equivalent to $(which foo)
setopt NOBANGHIST            # disable old history syntax
setopt GLOB_DOTS             # glob matches files starting with dot; `*` becomes `*(D)`

unsetopt BG_NICE             # don't nice background jobs; not useful and doesn't work on WSL

function chpwd() ls  # run `ls` after every `cd`

function custom_rprompt() {}  # users can redefine this; its output is shown in RPROMPT

if [[ -f $HOME/mkport/mkport-env.zsh ]]; then
  source $HOME/mkport/mkport-env.zsh
fi
