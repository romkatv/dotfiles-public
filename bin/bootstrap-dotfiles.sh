#!/bin/bash

for repo in public private; do
  git clone --bare git@github.com:romkatv/dotfiles-"$repo".git "$HOME"/.dotfiles-"$repo"
  git --git-dir="$HOME"/.dotfiles-"$repo"/ --work-tree="$HOME" checkout -b master -u origin/master
done
