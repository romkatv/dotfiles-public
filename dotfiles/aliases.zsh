alias diff='diff --color=auto'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias clang-format='clang-format -style=file'
alias ls='ls --group-directories-first --color=auto'
alias tree='tree -aC -I .git --dirsfirst'
alias gedit='gedit &>/dev/null'
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
  hash -d r=/mnt/d/r
  hash -d h=$(wslpath $(win_env USERPROFILE))
fi

function sync-dotfiles() {
  emulate -L zsh
  setopt err_return no_unset xtrace

  function _sync-dotfiles-public() { dotfiles-public "$@" }
  function _sync-dotfiles-private() { dotfiles-private "$@" }

  function _sync-dotfiles-repo() {
    local git=_sync-dotfiles-$1
    local -i dirty
    local s && s="$($git status --porcelain --untracked-files=no)"
    [[ -z $s ]] || {
      dirty=1
      $git stash
    }

    $git pull --rebase --no-recurse-submodules

    ! $git remote get-url upstream &>/dev/null || {
      $git fetch upstream
      $git merge upstream/master
    }

    $git push
    (( !dirty )) || $git stash pop

    $git pull --recurse-submodules
    $git submodule update --init
  }

  {
    pushd ~

    _sync-dotfiles-repo public

    [[ ! -f $HISTFILE ]] || {
      dotfiles-private add -f $HISTFILE
      local s && s="$(dotfiles-private status --porcelain $HISTFILE)"
      [[ -z $s ]] || dotfiles-private commit -m 'fresh history' $HISTFILE
    }
    _sync-dotfiles-repo private
  } always {
    popd
    unfunction _sync-dotfiles-{public,private,repo}
  }
}
