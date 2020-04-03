#!/usr/bin/env zsh
#
# Usage: ssh.zsh [ssh-options] [user@]hostname
#
# This is a replacement for `ssh [ssh-options] [user@]hostname` that fires
# up Zsh on the remote machine with a decent config.
#
# Here's what it does:
#
#   1. If you have `~/.p10k.zsh` on the local machine, it gets archived and
#      sent to the remote machine. If the file exists on the remote machine
#      it gets overwritten. It's easy to customize the list of files
#      that get sent this way. See `local_files` below.
#   2. If there is no Zsh on the remote machine, the version from
#      https://github.com/romkatv/zsh-bin gets installed to `~/.zsh-bin`.
#   3. If there is no `~/.zshrc` on the remote machine, the version from
#      https://github.com/romkatv/zsh4humans gets installed.
#
# This gives you fairly good Zsh experience over SSH with history, completions,
# etc.
#
# The remote machine must have login shell compatible with the Bourne shell.

emulate zsh -o pipefail -o extended_glob

# If there is no zsh on the remote machine, install this.
local zsh_url='https://raw.githubusercontent.com/romkatv/zsh-bin/master/install'
# If there is no ~/.zshrc on the remote machine, install this.
local zshrc_url='https://raw.githubusercontent.com/romkatv/zsh4humans/master/.zshrc'

# Copy all these files and directories (relative to $HOME) from local machine
# to remote. Silently skip files that don't exist locally and override existing
# files on the remote machine.
local local_files=(.p10k.zsh)

if (( ARGC == 0 )); then
  print -ru2 -- 'usage: ssh.zsh [ssh-options] [user@]hostname'
  return 1
fi

# Tar, compress and base64-encode $local_files.
local dump
local_files=(~/$^local_files(N))
dump=$(tar -C ~ -pczT <(print -rl -- ${(@)local_files#$HOME/}) | base64) || return

ssh -t "$@" '
  set -ue
  printf "%s" '${(q)dump//$'\n'}' | base64 -d | tar -C ~ -xzpo
  fetch() {
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL -- "$1"
    else
      wget -O- -- "$1"
    fi
  }
  if [ ! -e ~/.zshrc ]; then
    fetch '${(q)zshrc_url}' >~/.zshrc.tmp.$$
    mv ~/.zshrc.tmp.$$ ~/.zshrc
  fi
  if ! command -v zsh >/dev/null 2>&1; then
    if [ ! -d ~/.zsh-bin ]; then
      fetch '${(q)zsh_url}' | sh
      [ -d ~/.zsh-bin ]
    fi
    export PATH="$PATH:$HOME/.zsh-bin/bin"
  fi
  exec zsh -il'
