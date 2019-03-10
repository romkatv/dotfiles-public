export ZSH=$HOME/.oh-my-zsh

# See https://github.com/bhilburn/powerlevel9k for configuration options.
ZSH_THEME=powerlevel10k/powerlevel10k

POWERLEVEL9K_MODE=nerdfont-complete                   # use exotic symbols
POWERLEVEL9K_MAX_CACHE_SIZE=10000                     # clear in-memory cache when it grows too big
POWERLEVEL9K_PROMPT_ON_NEWLINE=true                   # user commands on new line
POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0       # show execution time
POWERLEVEL9K_CUSTOM_RPROMPT=custom_rprompt            # user-defined custom_rprompt()

POWERLEVEL9K_ROOT_ICON=\\uF09C                        # unlocked lock glyph
POWERLEVEL9K_TIME_ICON=\\uF017                        # clock glyph
POWERLEVEL9K_CUSTOM_RPROMPT_ICON=\\uF005              # star glyph

POWERLEVEL9K_TIME_BACKGROUND=magenta
POWERLEVEL9K_CUSTOM_RPROMPT_BACKGROUND=blue
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=grey
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=black
POWERLEVEL9K_STATUS_OK_BACKGROUND=grey53
POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=orange1
POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=black

GITSTATUS_ENABLE_LOGGING=1
# GITSTATUS_DAEMON=/home/romka/.oh-my-zsh/custom/plugins/gitstatus/gitstatusd
# POWERLEVEL9K_GITSTATUS_DIR=~/.oh-my-zsh/custom/plugins/gitstatus

# (( WSL )) && POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  root_indicator # display an unlocked lock glyph when root
  dir_writable   # display a locked lock glyph when the current dir isn't writable
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
  zsh-prompt-benchmark     # function zsh_prompt_benchmark to benchmark prompt
  zsh-syntax-highlighting  # syntax highlighting for prompt
  zsh-autosuggestions      # suggests commands as you type, based on command history (grey text)
  command-not-found        # use ubuntu's command-not-found on unrecognized command
  dirhistory               # alt-left and alt-right to navigate dir history; alt-up for `cd ..`
  extract                  # `extract <archive>` command
  z                        # `z` command to cd into commonly used directories
)

typeset -g __local_searching __local_savecursor

# This zle widget replaces the standard widget bound to Up (up-line-or-beginning-search). The
# original widget is bound to Ctrl+Up. The only difference between the two is the history they use.
# The standard widget uses global history while our replacement uses local history.
#
# Ideally, this function would be implemented like this:
#
#   zle .set-local-history 1
#   zle .up-line-or-beginning-search
#   zle .set-local-history 0
#
# This doesn't work though. If you type "foo bar" and press Up once, you'll get the last command
# from local history that starts with "foo bar", such as "foo bar baz". This is great. However, if
# you press Up again, you'll get the previous command from local history that starts with
# "foo bar baz" rather than with "foo bar". This is brokarama.
#
# We can attempt to fix this by replacing "up-line-or-beginning-search" with "up-line-or-search" but
# then we'll be cycling through commands that start with "foo" rather than "foo bar". This is
# craporama.
#
# To solve this problem I copied and modified the definition of down-line-or-beginning-search from
# https://github.com/zsh-users/zsh/blob/master/Functions/Zle/down-line-or-beginning-search. God
# bless Open Source.
function up-line-or-beginning-search-local() {
  emulate -L zsh
  local LAST=$LASTWIDGET
  zle .set-local-history 1
  if [[ $LBUFFER == *$'\n'* ]]; then
    zle .up-line-or-history
    __local_searching=''
  elif [[ -n $PREBUFFER ]] && zstyle -t ':zle:up-line-or-beginning-search' edit-buffer; then
    zle .push-line-or-edit
  else
    [[ $LAST = $__local_searching ]] && CURSOR=$__local_savecursor
    __local_savecursor=$CURSOR
    __local_searching=$WIDGET
    zle .history-beginning-search-backward
    zstyle -T ':zle:up-line-or-beginning-search' leave-cursor && zle .end-of-line
  fi
  builtin zle set-local-history 0
}

# Same as above but for Down.
function down-line-or-beginning-search-local() {
  emulate -L zsh
  local LAST=$LASTWIDGET
  zle .set-local-history 1
  function impl() {
    if [[ ${+NUMERIC} -eq 0 && ( $LAST = $__local_searching || $RBUFFER != *$'\n'* ) ]]; then
      [[ $LAST = $__local_searching ]] && CURSOR=$__local_savecursor
      __local_searching=$WIDGET
      __local_savecursor=$CURSOR
      if zle .history-beginning-search-forward; then
        if [[ $RBUFFER != *$'\n'* ]]; then
          zstyle -T ':zle:down-line-or-beginning-search' leave-cursor && zle .end-of-line
        fi
        return
      fi
      [[ $RBUFFER = *$'\n'* ]] || return
    fi
    __local_searching=''
    zle .down-line-or-history
  }
  impl
  zle .set-local-history 0
}

zle -N up-line-or-beginning-search-local
zle -N down-line-or-beginning-search-local

source $ZSH/oh-my-zsh.sh

ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  up-line-or-beginning-search-local
  down-line-or-beginning-search-local
)

zle_highlight=(default:bold)  # bold prompt

alias clang-format='clang-format -style=file'
alias ls='ls --group-directories-first --color=auto'
alias gedit='gedit &>/dev/null'                       # suppress useless warnings
alias d2u='dos2unix'
alias u2d='unix2dos'

# If you want some random config file to be versioned in the dotfiles-public git repo, type
# `dotfiles-public add -f <random-file>`. Use `commit`, `push`, etc., as with normal git.
alias dotfiles-public='git --git-dir=$HOME/.dotfiles-public/.git --work-tree=$HOME'
alias dotfiles-private='git --git-dir=$HOME/.dotfiles-private/.git --work-tree=$HOME'

alias x='xsel --clipboard -i'  # cut to clipboard
alias v='xsel --clipboard -o'  # paste from clipboard
alias c='x && v'               # copy to clipboard

if (( WSL )); then
  # Prints Windows environment variable $1.
  function win_env() {
    emulate -L zsh
    echo -E ${$(/mnt/c/Windows/System32/cmd.exe /c "echo %$1%")%$'\r'}
  }
fi

# Automatically run `ls` after every `cd`.
function _chpwd_hook_ls() ls
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _chpwd_hook_ls

function custom_rprompt() {}  # redefine this to show stuff in RPROMPT

bindkey '^H'      backward-kill-word                  # ctrl+bs   delete previous word
bindkey '^[[3;5~' kill-word                           # ctrl+del  delete next word
bindkey '^J'      backward-kill-line                  # ctrl+j    delete everything before cursor
bindkey '^Z'      undo                                # ctrl+z    undo
bindkey '^Y'      redo                                # ctrl+y    redo
bindkey '^[OA'    up-line-or-beginning-search-local   # ctrl+up   previous command in local history
bindkey '^[OB'    down-line-or-beginning-search-local # ctrl+down next command in local history
bindkey '^[[1;5A' up-line-or-beginning-search         # ctrl+up   previous command in global history
bindkey '^[[1;5B' down-line-or-beginning-search       # ctrl+down next command in global history

stty susp '^B'  # ctrl+b instead of ctrl+z to suspend (ctrl+z is undo)

HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILESIZE=1000000000

setopt HIST_IGNORE_SPACE     # don't add commands starting with space to history
setopt HIST_VERIFY           # if a cmd triggers history expansion, show it instead of running
setopt HIST_REDUCE_BLANKS    # remove junk whitespace from commands before adding to history
setopt EXTENDED_GLOB         # (#qx) glob qualifier and more
setopt NO_BANG_HIST          # disable old history syntax
setopt GLOB_DOTS             # glob matches files starting with dot; `*` becomes `*(D)`
setopt MULTIOS               # allow multiple redirections for the same fd

unsetopt BG_NICE             # don't nice background jobs; not useful and doesn't work on WSL

if (( WSL )); then
  # Place temporary files created by `=(command)` in the Windows temp directory.
  # This makes it easy to pass file arguments to native Windows apps.
  TMPPREFIX=$WIN_TMPDIR/zsh
fi

# This affects every invocation of `less`.
#
#   -R   color
#   -F   exit if there is less than one page of content
#   -X   keep content on screen after exit
#   -M   show more info at the bottom prompt line
#   -x4  tabs are 4 instead of 8
export LESS=-RFXMx4

if [[ -f $HOME/mkport/mkport-env.zsh ]]; then
  source $HOME/mkport/mkport-env.zsh
fi
