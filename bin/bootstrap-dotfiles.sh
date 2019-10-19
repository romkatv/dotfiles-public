#!/bin/bash
#
# Clones dotfiles-public and dotfiles-private from github. Requires `git` and ssh
# keys for github.

set -xueEo pipefail

if [[ -z "${GITHUB_USERNAME:-}" ]]; then
  echo "ERROR: GITHUB_USERNAME not set" >&2
  exit 1
fi

function get_repo_uri() {
  echo "git@github.com:$GITHUB_USER/$1.git"
}

function list_files() {
  set -eE
  local repo=$1
  local tmp
  tmp=$(mktemp -d)
  git clone "$(get_repo_uri "$repo")" "$tmp"
  pushd "$tmp" &>/dev/null
  if ! git rev-parse --verify master &>/dev/null; then
    git checkout -b master
    git commit -m 'create master' --allow-empty
    git push -u origin master
  fi
  local files
  files=$(git ls-tree -r --name-only master)
  popd &>/dev/null
  rm -rf "$tmp"
  echo "$files"
}

function backup_files() {
  local files=$1
  local backup_dir=$2

  if test -d "$backup_dir"; then
    echo "Error: backup directory already exists: $backup_dir" >&2
    return 1
  fi

  mkdir -p "$backup_dir"
  pushd "$HOME"
  while read -r file; do
    if test -f "$file"; then
      cp --parents -a "$file" "$backup_dir"
    fi
  done <<<"$files"
  popd
}

function restore_files() {
  local backup_dir=$1
  pushd "$backup_dir"
  while read -r file; do
    if ! cp --parents -a -f "$file" "$HOME"; then
      echo "ERROR: cannot restore $HOME/$file from backup in $backup_dir/$f" >&2
      return 1
    fi
  done < <(find . -type f)
  popd
  rm -rf "$backup_dir"
}

function clone_repo() {
  local repo=$1
  local git_dir="$HOME/.$repo/.git"

  if test -d "$git_dir"; then
    echo "Error: git directory already exists: $git_dir" >&2
    return 1
  fi

  local backup_dir="$HOME/$repo.original"
  local files
  files=$(list_files "$repo")
  backup_files "$files" "$backup_dir"

  trap "restore_files '$backup_dir'" INT TERM EXIT

  pushd "$HOME"
  xargs -0 rm -f <<<"$files"
  popd

  git clone --bare "$(get_repo_uri "$repo")" "$git_dir"
  git --git-dir="$git_dir"/ --work-tree="$HOME" checkout master
  git --git-dir="$git_dir"/ --work-tree="$HOME" push -u origin master
  git --git-dir="$git_dir"/ --work-tree="$HOME" submodule update --init --recursive
  git --git-dir="$git_dir"/ --work-tree="$HOME" config --local status.showUntrackedFiles no

  restore_files "$backup_dir"
  trap - INT TERM EXIT
}

if [[ "$(id -u)" == 0 ]]; then
  echo "bootstrap-dotfiles.sh: please run as non-root" >&2
  exit 1
fi

clone_repo dotfiles-public
clone_repo dotfiles-private
