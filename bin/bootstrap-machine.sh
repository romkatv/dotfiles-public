#!/bin/bash

set -xueEo pipefail

if [[ -z "${GITHUB_USERNAME-}" ]]; then
  echo "ERROR: GITHUB_USERNAME not set" >&2
  exit 1
fi

umask o-w

if [[ ! -f ~/.ssh/id_rsa || ! -f ~/.ssh/id_rsa.pub ]]; then
  if [[ -z "${WSL_DISTRO_NAME-}" ]]; then
    echo "ERROR: Put your ssh keys at ~/.ssh and retry" >&2
    exit 1
  fi

  mkdir -p ~/.ssh
  chmod 755 ~/.ssh

  win_home="$(cd /mnt/c && cmd.exe /c "echo %HOMEDRIVE%%HOMEPATH%" | sed 's/\r$//')"
  downloads="$(wslpath "$win_home")/Downloads"

  if [[ -f "$downloads"/id_rsa ]]; then
    cp "$downloads"/id_rsa ~/.ssh
  elif [[ -f "$downloads"/id_rsa.txt ]]; then
    cp "$downloads"/id_rsa.txt ~/.ssh/id_rsa
  else
    echo "ERROR: Put your ssh keys at ~/.ssh or ${downloads@Q} and retry" >&2
    exit 1
  fi

  chmod 600 ~/.ssh/id_rsa
fi

ssh_agent="$(ssh-agent -st 20h)"
eval "$ssh_agent"
trap 'ssh-agent -k >/dev/null' INT TERM EXIT
ssh-add ~/.ssh/id_rsa
if [[ ! -e ~/.ssh/id_rsa.pub ]]; then
  ssh-add -L >~/.ssh/id_rsa.pub
  chmod 644 ~/.ssh/id_rsa.pub
fi

if [[ ! -e ~/.ssh/control-master ]]; then
  mkdir ~/.ssh/control-master
  chmod 755 ~/.ssh/control-master
fi

rm -rf ~/.cache

sudo apt-get update
sudo sh -c 'DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade -y'
sudo apt-get autoremove -y
sudo apt-get autoclean

sudo apt-get install -y git curl zsh
tmpdir="$(mktemp -d)"
git clone --depth=1 -- git@github.com:"$GITHUB_USERNAME"/dotfiles-public.git "$tmpdir"
bootstrap="$(<"$tmpdir"/bin/bootstrap-dotfiles.sh)"
rm -rf -- "$tmpdir"
bash -c "$bootstrap"

zsh -fec 'fpath=(~/dotfiles/functions $fpath); autoload -Uz sync-dotfiles; sync-dotfiles'

bash ~/bin/setup-machine.sh

if [[ -f ~/bin/bootstrap-machine-private.sh ]]; then
  bash ~/bin/bootstrap-machine-private.sh
fi

if [[ -t 0 && -n "${WSL_DISTRO_NAME-}" ]]; then
  read -p "Need to restart WSL to complete installation. Terminate WSL now? [y/N] " -n 1 -r
  echo
  if [[ ${REPLY,,} == @(y|yes) ]]; then
    wsl.exe --terminate "$WSL_DISTRO_NAME"
  fi
fi
