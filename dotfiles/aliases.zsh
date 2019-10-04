alias diff='diff --color=auto'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias clang-format='clang-format -style=file'
alias ls='ls --group-directories-first --color=auto'
alias tree='tree -aC -I .git --dirsfirst'
alias gedit='gedit &>/dev/null'
alias d2u='dos2unix'
alias u2d='unix2dos'

if [[ -d ~/.dotfiles-public ]]; then
  alias dotfiles-public='git --git-dir="$HOME"/.dotfiles-public/.git --work-tree="$HOME"'
fi
if [[ -d ~/.dotfiles-private ]]; then
  alias dotfiles-private='git --git-dir="$HOME"/.dotfiles-private/.git --work-tree="$HOME"'
fi

alias x='xsel --clipboard -i'  # cut to clipboard
alias v='xsel --clipboard -o'  # paste from clipboard
alias c='x && v'               # copy to clipboard

if (( WSL )); then
  # Prints the value of Windows environment variable $1 or "%$1%" if there is
  # no such variable.
  function win_env() {
    emulate -L zsh
    (( ARGC == 1 && $#1 )) || { echo 'usage: win_env <name>' >&2; return 1 }
    local val && val="$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c "echo %$1%")" || return
    echo -E - ${val%$'\r'}
  }
  # The same as double-cliking on file/dir $1 in Windows Explorer.
  function xopen() {
    emulate -L zsh
    (( ARGC == 1 && $#1 )) || { echo 'usage: xopen <path>' >&2; return 1 }
    local arg && arg="$(wslpath -wa "$1")" || return
    ( cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c start "$arg" )
  }
  hash -d r=/mnt/d/r
  hash -d h="$(wslpath "$(win_env USERPROFILE)")"
else
  # The same as double-cliking on file/dir $1 in X File Manager.
  function xopen() {
    emulate -L zsh
    xdg-open "$@" &>/dev/null &!
  }
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
    {
      pushd ~

      (( !$+aliases[dotfiles-public] )) || _sync-dotfiles-repo public

      (( !$+aliases[dotfiles-private] )) || {
        [[ ! -f $HISTFILE ]] || {
          dotfiles-private add $HISTFILE
          local s && s="$(dotfiles-private status --porcelain $HISTFILE)"
          [[ -z $s ]] || dotfiles-private commit -m 'fresh history' $HISTFILE
        }
        _sync-dotfiles-repo private
      }
    } always {
      popd
    }
  } always {
    unfunction _sync-dotfiles-{public,private,repo}
  }
}
