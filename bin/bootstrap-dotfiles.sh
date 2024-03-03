#!/bin/bash
#
# Clones dotfiles-public and dotfiles-private from github. Requires `git` and ssh
# keys for github.

set -xueEo pipefail

if [[ -z "${GITHUB_USERNAME:-}" ]]; then
  echo "ERROR: GITHUB_USERNAME not set" >&2
  exit 1
fi

function clone_repo() {
  local repo=$1
  local git_dir="$HOME/.$repo"
  local uri="git@github.com:$GITHUB_USERNAME/$repo.git"

  if [[ -e "$git_dir" ]]; then
    return 0
  fi

  git --git-dir="$git_dir" init -b master
  git --git-dir="$git_dir" config core.bare false
  git --git-dir="$git_dir" config status.showuntrackedfiles no
  git --git-dir="$git_dir" remote add origin "$uri"
  git --git-dir="$git_dir" fetch
  git --git-dir="$git_dir" reset origin/master
  git --git-dir="$git_dir" branch -u origin/master
  git --git-dir="$git_dir" checkout -- .
  git --git-dir="$git_dir" submodule update --init --recursive
}

if [[ "$(id -u)" == 0 ]]; then
  echo "bootstrap-dotfiles.sh: please run as non-root" >&2
  exit 1
fi

clone_repo dotfiles-public
clone_repo dotfiles-private

if [[ "$GITHUB_USERNAME" != romkatv ]]; then
  git --git-dir="$HOME"/.dotfiles-public \
    remote add upstream 'https://github.com/romkatv/dotfiles-public.git'
fi
