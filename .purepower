# Original location: https://github.com/romkatv/dotfiles-public/blob/master/.purepower.
# If you copy this file, keep the link to the original and this sentence intact; you are encouraged
# to change everything else.
#
# This file defines configuration options for Powerlevel10k ZSH theme that will make your prompt
# lightweight and sleek, unlike the default bulky look. You can also use it with Powerlevel9k -- a
# great choice if you need an excuse to have a cup of coffee after every command you type.
#
# This is how it'll look:
# https://raw.githubusercontent.com/romkatv/dotfiles-public/master/dotfiles/purepower.png.
#
# Pure Power needs to be installed in addition to Powerlevel10k, not instead of it. Pure Power
# defines a set of configuration parameters that affect the styling of Powerlevel10k; there is no
# code in it.
#
#                         PHILOSOPHY
#
# This configuration is made for those who care about style and value clear UI without redundancy
# and tacky ornaments that serve no function.
#
#   * No overwhelming background that steals attention from real content on your screen.
#   * No redundant icons. A clock icon next to the current time takes space without conveying any
#     information. This is your personal prompt -- you don't need an icon to remind you that the
#     segment on the right shows current time.
#   * No separators between prompt segments. Different foreground colors are enough to keep them
#     visually distinct.
#   * Bright colors for important things, low-contrast colors for everything else.
#   * No needless color switching. The number of stashes you have in a git repository is always
#     green. Since its meaning is the same in a clean and in a dirty repository, it doesn't change
#     color.
#   * Works with any font.
#
#                         LEFT PROMPT
#
#   * Your current directory is bright blue when it's writable and brownish when not.
#   * The prompt symbol on the left is '❮' when vicmd keymap is active and '❯' otherwise. It's green
#     if the last command has succeeded and red if it has failed.
#   * Git prompt colors:
#     * Grey: prompt is refreshing in the background (happens only in large repositories).
#     * Green: clean (no stated or unstaged changes and no untracked files).
#     * Yellow: dirty (some stated or unstaged changes).
#     * Teal: some untracked files but otherwise clean (no staged or unstaged changes).
#   * Git prompt icons:
#     * '@12345678' (git prompt color): detached HEAD at commit 12345678.
#     * 'my-feature' (git prompt color): on branch my-feature.
#     * 'my-feature|master' (git prompt color): on branch my-feature tracking remote branch master.
#     * '#my-release' (git prompt color): on tag my-release.
#     * '+' (yellow): staged changes.
#     * '!' (yellow): unstaged changes.
#     * '?' (teal): untracked files.
#     * '⇡42' (green): 42 commits ahead of remote.
#     * '⇣42' (green): 42 commits behind remote.
#     * '*42' (green): 42 stashes.
#
#                        RIGHT PROMPT
#
#   * Error code with an optional signal name of the last command if it failed, in red.
#   * Last command execution time (in seconds).
#   * '⇶' if you have background jobs.
#   * user@host in bright yellow if root, grey otherwise.
#   * If you type `custom_rprompt() { echo 'message' }` in your terminal, you'll get 'message' shown
#     on the right. Useful for integration with your scripts that change some sort of
#     state/environment.
#
#                       INSTALLATION
#
# 1. Copy this file to your home directory.
#
#    ( cd && curl -fsSLO https://raw.githubusercontent.com/romkatv/dotfiles-public/master/.purepower )
#
# 2. Source the file from ~/.zshrc.
#
#    echo 'source ~/.purepower' >>! ~/.zshrc
#
# 3. Enable Powerlevel10k ZSH theme. The easiest way is this:
#
#    git clone https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
#    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>! ~/.zshrc
#
# If you are using a plugin manager, see https://github.com/romkatv/powerlevel10k for installation
# options.
#
#                       CONFIGURATION
#
# You can set PURE_POWER_MODE before sourcing ~/.purepower to restrict the range of used characters.
#
#   * PURE_POWER_MODE=fancy     use unicode characters in the prompt (default)
#   * PURE_POWER_MODE=portable  use only ascii characters in the prompt
#
# You can switch mode on the fly by setting PURE_POWER_MODE and executing zsh. Useful when you end
# up in a prehistoric environment and see gibberish on your screen.
#
#   PURE_POWER_MODE=portable exec zsh  # switch to portable mode
#   PURE_POWER_MODE=fancy    exec zsh  # switch to fancy mode
#
# To automatically switch to portable mode when logging in from a terminal that doesn't support
# unicode, put the following incantation in your ~/.zshrc.
#
#   [[ $TERM == xterm* ]] || : ${PURE_POWER_MODE:=portable}
#   source ~/.purepower
#
# To configure what gets shown in the prompt, edit ~/.purepower. See
# https://github.com/romkatv/powerlevel10k/blob/master/README.md#installation-and-configuration for
# configuration options. Prompt configuration is a deeply personal affair, so take your time to
# craft the right prompt just for you. The stock configuration is merely a starting point, a source
# of inspiration, a frame for your own creation. Mercilessly slash everything of little value to
# you. Don't care how long commands take to execute? Get rid of command_execution_time segment!
# Boldly mold prompt pieces useful to you to ensure a perfect fit to your workflow and aesthetic
# preferences. Take full advantage of powerlevel over 9k!
#
# Remember that colors looks differently in different terminals. Use this script to choose what
# works best for you.
#
#   for i in {0..255}; do print -P "%F{${(l:3::0:)i}}${(l:3::0:)i} TEST%f"; done
#
# Keep in mind that some prompt segments can appear and disappear depending on the state of your
# environment. Make sure colors work well in every situation. Neighboring segments should always
# have distinct colors.
#
# Try different fonts. Pure Power doesn't use esoteric symbols even in fancy mode and thus doesn't
# require a patched font. Any monospace font will do, although some are notoriously bad at
# displaying non-ascii symbols in terminals.
#
# If you are using Pure Power with Powerlevel9k rather than Powerlevel10k, you'll need to set
# PURE_POWER_USE_P10K_EXTENSIONS=0 before sourcing ~/.purepower or you'll see gibberish in your left
# prompt. This option will turn off vi keymap integration, so your prompt symbol will always be '❯'.
# Your prompt will also be 10-100 times slower with Powerlevel9k. This is not the fault of Pure
# Power. Powerlevel9k is slow with any styling.
#
#                       ATTRIBUTION
#
# Visual design of this configuration borrows heavily from https://github.com/sindresorhus/pure.
# Recreation of Pure look and feel in Powerlevel10k was inspired by
# https://github.com/iboyperson/p9k-theme-pastel. The origin myth is chiseled onto
# https://www.reddit.com/r/zsh/comments/b45w6v/.

if test -z "${ZSH_VERSION}"; then
  echo "purepower: unsupported shell; try zsh instead" >&2
  return 1
  exit 1
fi

() {
  emulate -L zsh && setopt no_unset pipe_fail

  typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
      dir  # current directory
      vcs  # git status
  )

  typeset -ga POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
      status                  # exit code of the last command
      command_execution_time  # duration of the last command
      background_jobs         # presence of background jobs
      # virtualenv            # python virtual environment (https://docs.python.org/3/library/venv.html)
      # anaconda              # conda environment (https://conda.io/)
      # pyenv                 # python environment (https://github.com/pyenv/pyenv)
      # kubecontext           # current kubernetes context (https://kubernetes.io/)
      custom_rprompt          # the output of function `custom_rprompt()` if it is defined
      context                 # user@host
      # time                  # current time
  )

  # `$(_pp_c x y`) evaluates to `y` if the terminal supports >= 256 colors and to `x` otherwise.
  zmodload zsh/terminfo
  if (( terminfo[colors] >= 256 )); then
    function _pp_c() { print -nr -- $2 }
  else
    function _pp_c() { print -nr -- $1 }
    typeset -g POWERLEVEL9K_IGNORE_TERM_COLORS=true
  fi

  # `$(_pp_s x y`) evaluates to `x` in portable mode and to `y` in fancy mode.
  if [[ ${PURE_POWER_MODE:-fancy} == fancy ]]; then
    function _pp_s() { print -nr -- $2 }
  else
    if [[ $PURE_POWER_MODE != portable ]]; then
      echo -En "purepower: invalid mode: ${(qq)PURE_POWER_MODE}; " >&2
      echo -E  "valid options are 'fancy' and 'portable'; falling back to 'portable'" >&2
    fi
    function _pp_s() { print -nr -- $1 }
  fi

  local ins=$(_pp_s '>' '❯')
  local cmd=$(_pp_s '<' '❮')
  if (( ${PURE_POWER_USE_P10K_EXTENSIONS:-1} )); then
    local p="\${\${\${KEYMAP:-0}:#vicmd}:+${${ins//\\/\\\\}//\}/\\\}}}"
    p+="\${\${\$((!\${#\${KEYMAP:-0}:#vicmd})):#0}:+${${cmd//\\/\\\\}//\}/\\\}}}"
  else
    local p=$ins
  fi

  if (( ${PURE_POWER_USE_P10K_EXTENSIONS:-1} )); then
    typeset -g POWERLEVEL9K_SHOW_RULER=true
    typeset -g POWERLEVEL9K_RULER_CHAR=$(_pp_s '-' '─')
    typeset -g POWERLEVEL9K_RULER_BACKGROUND=none
    typeset -g POWERLEVEL9K_RULER_FOREGROUND=$(_pp_c 7 237)
  else
    typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
    function custom_rprompt() { }
  fi

  typeset -g POWERLEVEL9K_LEFT_SEGMENT_END_SEPARATOR=
  typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
  typeset -g POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{%(?.$(_pp_c 2 76).$(_pp_c 1 196))}$p%f "

  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_WHITESPACE_BETWEEN_{LEFT,RIGHT}_SEGMENTS=

  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=true
  typeset -g POWERLEVEL9K_DIR_{ETC,HOME,HOME_SUBFOLDER,DEFAULT,NOT_WRITABLE}_BACKGROUND=none
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_FOREGROUND=$(_pp_c 3 209)
  typeset -g POWERLEVEL9K_DIR_{HOME,HOME_SUBFOLDER,ETC,DEFAULT}_FOREGROUND=$(_pp_c 4 39)
  typeset -g POWERLEVEL9K_{ETC,FOLDER,HOME,HOME_SUB,LOCK}_ICON=
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=false

  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED,LOADING}_BACKGROUND=none
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$(_pp_c 2 76)
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$(_pp_c 6 14)
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$(_pp_c 3 11)
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=$(_pp_c 5 244)
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_UNTRACKEDFORMAT_FOREGROUND=$POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_UNSTAGEDFORMAT_FOREGROUND=$POWERLEVEL9K_VCS_MODIFIED_FOREGROUND
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_STAGEDFORMAT_FOREGROUND=$POWERLEVEL9K_VCS_MODIFIED_FOREGROUND
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_INCOMING_CHANGESFORMAT_FOREGROUND=$POWERLEVEL9K_VCS_CLEAN_FOREGROUND
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_OUTGOING_CHANGESFORMAT_FOREGROUND=$POWERLEVEL9K_VCS_CLEAN_FOREGROUND
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_STASHFORMAT_FOREGROUND=$POWERLEVEL9K_VCS_CLEAN_FOREGROUND
  typeset -g POWERLEVEL9K_VCS_{CLEAN,UNTRACKED,MODIFIED}_ACTIONFORMAT_FOREGROUND=1
  typeset -g POWERLEVEL9K_VCS_LOADING_ACTIONFORMAT_FOREGROUND=$POWERLEVEL9K_VCS_LOADING_FOREGROUND
  typeset -g POWERLEVEL9K_VCS_{GIT,GIT_GITHUB,GIT_BITBUCKET,GIT_GITLAB,BRANCH}_ICON=
  typeset -g POWERLEVEL9K_VCS_REMOTE_BRANCH_ICON=$'%{\b|%}'
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=$(_pp_s '<' '⇣')
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=$(_pp_s '>' '⇡')
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='*'
  typeset -g POWERLEVEL9K_VCS_TAG_ICON=$'%{\b#%}'
  if (( ${PURE_POWER_USE_P10K_EXTENSIONS:-1} )); then
    typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED}_MAX_NUM=99
    typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
    typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='!'
    typeset -g POWERLEVEL9K_VCS_STAGED_ICON='+'
  else
    typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON=$'%{\b?%}'
    typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON=$'%{\b!%}'
    typeset -g POWERLEVEL9K_VCS_STAGED_ICON=$'%{\b+%}'
  fi

  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_BACKGROUND=none
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$(_pp_c 1 9)
  typeset -g POWERLEVEL9K_CARRIAGE_RETURN_ICON=

  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=none
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$(_pp_c 5 101)
  typeset -g POWERLEVEL9K_EXECUTION_TIME_ICON=

  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=none
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_COLOR=2
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_ICON=$(_pp_s '%%' '⇶')

  typeset -g POWERLEVEL9K_CUSTOM_RPROMPT=custom_rprompt
  typeset -g POWERLEVEL9K_CUSTOM_RPROMPT_BACKGROUND=none
  typeset -g POWERLEVEL9K_CUSTOM_RPROMPT_FOREGROUND=$(_pp_c 4 12)

  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,ROOT,REMOTE_SUDO,REMOTE,SUDO}_BACKGROUND=none
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,REMOTE_SUDO,REMOTE,SUDO}_FOREGROUND=$(_pp_c 7 244)
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=$(_pp_c 3 11)

  typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND=none
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=6
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=true
  typeset -g POWERLEVEL9K_VIRTUALENV_LEFT_DELIMITER=
  typeset -g POWERLEVEL9K_VIRTUALENV_RIGHT_DELIMITER=

  typeset -g POWERLEVEL9K_ANACONDA_BACKGROUND=none
  typeset -g POWERLEVEL9K_ANACONDA_FOREGROUND=6
  typeset -g POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION=true
  typeset -g POWERLEVEL9K_ANACONDA_LEFT_DELIMITER=
  typeset -g POWERLEVEL9K_ANACONDA_RIGHT_DELIMITER=

  typeset -g POWERLEVEL9K_PYENV_BACKGROUND=none
  typeset -g POWERLEVEL9K_PYENV_FOREGROUND=6
  typeset -g POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=false

  # Icon for virtualenv, anaconda and pyenv.
  typeset -g POWERLEVEL9K_PYTHON_ICON=

  # Don't show trailing "/default" in kubernetes context.
  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_DEFAULT_NAMESPACE=false
  # Kubernetes context classes for the purpose of using different colors with different contexts.
  #
  # POWERLEVEL9K_KUBECONTEXT_CLASSES is an array with even number of elements. The first element in
  # each pair defines a pattern against which the current kubernetes context (in the format it is
  # displayed in the prompt) gets matched. The second element defines the context class. Patterns
  # are tried in order. The first match wins.
  #
  # For example, if your current kubernetes context is "deathray-testing", its class is TEST because
  # "deathray-testing" doesn't match the pattern '*prod*' but does match '*test*'. Hence it'll be
  # shown with the color of $POWERLEVEL9K_KUBECONTEXT_TEST_FOREGROUND.
  typeset -g POWERLEVEL9K_KUBECONTEXT_CLASSES=(
      '*prod*'  PROD
      '*test*'  TEST
      '*'       DEFAULT)
  typeset -g POWERLEVEL9K_KUBECONTEXT_{PROD,TEST,DEFAULT}_BACKGROUND=none
  typeset -g POWERLEVEL9K_KUBECONTEXT_PROD_FOREGROUND=1
  typeset -g POWERLEVEL9K_KUBECONTEXT_TEST_FOREGROUND=2
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND=3
  typeset -g POWERLEVEL9K_KUBERNETES_ICON=

  typeset -g POWERLEVEL9K_TIME_BACKGROUND=none
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$(_pp_c 7 66)
  typeset -g POWERLEVEL9K_TIME_ICON=
  # Format for the time segment: 09:51:02. See `man 3 strftime`.
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'

  unfunction _pp_c _pp_s
} "$@"
