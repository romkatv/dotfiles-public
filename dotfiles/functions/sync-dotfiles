# This is a function because it needs to access HISTFILE.

emulate -L zsh -o no_unset -o no_prompt_subst -o prompt_percent -o pushd_silent

local GIT_DIR GIT_WORK_TREE
unset GIT_DIR GIT_WORK_TREE

local merge=1 OPTIND OPTARG
while getopts ":hm" opt; do
  case $opt in
    *h)
      print -r -- $'Usage: sync-dotfiles [{+|-}m]\nSynchronize local dotfiles with GitHub.'
      return 0
    ;;
    \?) print -r -- "sync-dotfiles: invalid option: $OPTARG" >&2;            return 1;;
    :)  print -r -- "sync-dotfiles: missing required argument: $OPTARG" >&2; return 1;;
    m)  merge=0;;
    +m) merge=1;;
  esac
done

if (( OPTIND <= ARGC )); then
  print -r -- "sync-dotfiles: unexpected positional argument: ${*[OPTIND]}" >&2
  return 1
fi

function -sync-dotfiles-repo() {
  local repo=${${GIT_DIR:t}#.} dirty=0 s
  s="$(git status --porcelain --untracked-files=no --ignore-submodules=dirty)" || return
  if [[ -n $s ]]; then
    dirty=1
    git stash || return
  fi

  print -Pr -- "%F{yellow}sync-dotfiles%f: pulling %B$repo%b" >&2
  if ! git pull --rebase --no-recurse-submodules && ! git pull --no-edit --no-recurse-submodules; then
    print -Pr -- "%F{red}sync-dotfiles%f: failed to pull %B$repo%b" >&2
    git status || return
    return 1
  fi

  if (( merge )) && git remote get-url upstream &>/dev/null; then
    print -Pr -- "%F{yellow}sync-dotfiles%f: merging upstream %B$repo%b" >&2
    git fetch upstream || return
    if ! git merge --no-edit upstream/master; then
      print -Pr -- "%F{red}sync-dotfiles%f: failed to merge upstream %B$repo%b" >&2
      git status || return
      return 1
    fi
  fi

  print -Pr -- "%F{yellow}sync-dotfiles%f: pushing %B$repo%b" >&2
  git push || return
  if (( dirty )); then
    git stash pop || return
  fi

  print -Pr -- "%F{yellow}sync-dotfiles%f: pulling submodules from %B$repo%b" >&2
  git pull --recurse-submodules || return
  git submodule update --init || return
}

{
  pushd -q ~ || return

  local -x GIT_DIR=~/.dotfiles-public
  -sync-dotfiles-repo || return

  GIT_DIR=~/.dotfiles-private
  local hist=${ZDOTDIR:-~}/.zsh_history.${(%):-%m}
  local -U hist=($hist{,:*}(N))
  [[ -f ${HISTFILE:-} ]] && hist+=($HISTFILE)
  if (( $#hist )); then
    git add -- $hist || return
    local s
    s="$(git status --porcelain -- $hist)" || return
    if [[ -n $s ]]; then
      git commit -m 'fresh history' -- $hist || return
    fi
  fi
  -sync-dotfiles-repo dotfiles-private || return
} always {
  unset -f -- -sync-dotfiles-repo
  popd -q
}
