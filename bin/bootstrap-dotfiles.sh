#!/bin/bash
#
# Clone dotfiles-public and dotfiles-private from github. Requires `git` and ssh
# keys for github.

set -xueEo pipefail

readonly GITHUB_USER=romkatv

function get_repo_uri() {
  echo "git@github.com:$GITHUB_USER/$1.git"
}

function list_files() {
  local repo=$1
  local tmp
  tmp=$(mktemp -d)
  git clone "$(get_repo_uri "$repo")" "$tmp"
  local files
  files=$(git --git-dir="$tmp"/.git --work-tree="$tmp" ls-tree -r --name-only master)
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
    cp --parents -a -f "$file" "$HOME"
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

  restore_files "$backup_dir"
  trap - INT TERM EXIT
}

clone_repo dotfiles-public
clone_repo dotfiles-private
