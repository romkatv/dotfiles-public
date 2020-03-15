#!/usr/bin/env zsh
#
# Usage: ssh.zsh [ssh-options] [user@]hostname

emulate zsh -o pipefail -o extended_glob

# If there is no zsh on the remote machine, install this version to ~/.ssh.zsh/zsh.
local zsh_url='https://github.com/xxh/zsh-portable/raw/50539a52a5f8947c10937fec9649fafa94487624/result/zsh-portable-${kernel}-${arch}.tar.gz'
# If there is no `git` on the remove machine, install this version to ~/.ssh.zsh/git.
local git_url='http://s.minos.io/archive/bifrost/${arch}/git-2.7.2-2.tar.gz'
local git_md5_url='http://s.minos.io/archive/bifrost/${arch}/md5sum.txt'
local git_sha512_url='http://s.minos.io/archive/bifrost/${arch}/sha512sum.txt'
# If there is no ~/.zshrc on the remote machine, download this.
local zshrc_url='https://raw.githubusercontent.com/romkatv/zsh4humans/c7c1a534a79c6537c68a651ab75540459dfa9798/.zshrc'

# Require these tools to be installed on the remote machine.
local required_tools=(uname mkdir rm mv chmod ln tar base64)

# Copy all these files and directories (relative to $HOME) from local machine to remote.
# Silently skip files that don't exist locally. Override existing files on the remote machine.
local local_files=(.p10k.zsh)

if (( ARGC == 0 )); then
  print -ru2 -- 'usage: ssh.zsh [ssh-options] [user@]hostname'
  return 1
fi

# Tar, compress and base64-encode $local_files.
local dump
local_files=(~/$^local_files(N))
if (( $#local_files )); then
  print -ru2 -- '[local] archiving files: '${(j:,:)${(@)local_files/#$HOME/'~'}}
  dump=$(tar -C ~ -pcz -- ${(@)local_files#$HOME/} | base64) || return
fi

# Template for checking whether TOOL is available (uname, chmod, etc.).
local check_tool=$(<<\END
if ! command -v TOOL >/dev/null 2>&1; then
  >&2 echo '[remote] `TOOL` not found on the remote machine'
  >&2 echo '  Opening a temporary shell (/bin/sh) so that you can install it.'
  >&2 echo '  When done, type `exit` to continue.'
  /bin/sh -i
  if ! command -v TOOL >/dev/null 2>&1; then
    >&2 echo '[remote] `TOOL` still not found; bailing out'
    exit 1
  fi
fi;
END
)

# Function that dispatches either to `curl` or `wget`, depending on what's available.
local fetch_init=$(<<\END
fetch_init() {
  local try
  for try in 1 2; do
    if command -v curl >/dev/null 2>&1; then
      fetch='curl -fsSL --'
      return
    elif command -v wget >/dev/null 2>&1; then
      fetch='wget -q -O- --'
      return
    elif [ "$try" -eq 1 ]; then
      >&2 echo '[remote] neither `curl` nor `wget` are found on the remote machine'
      >&2 echo '  Opening a temporary shell (/bin/sh) so that you can install one of them.'
      >&2 echo '  When done, type `exit` to continue.'
      /bin/sh -i
    else
      >&2 echo '[remote] `curl` and `wget` are still not found; bailing out'
      exit 1
    fi
  done
}
END
)

# Function that dispatches either to `shasum` or `md5sum`, depending on what's available.
local checksum_init=$(<<\END
checksum_init() {
  local try
  for try in 1 2; do
    if command -v shasum >/dev/null 2>&1; then
      checksum='shasum -a 512 --'
      return
    elif command -v md5sum >/dev/null 2>&1; then
      checksum='md5sum --'
      return
    elif [ "$try" -eq 1 ]; then
      >&2 echo '[remote] neither `shasum` nor `md5sum` are found on the remote machine'
      >&2 echo '  Opening a temporary shell (/bin/sh) so that you can install one of them.'
      >&2 echo '  When done, type `exit` to continue.'
      /bin/sh -i
    else
      >&2 echo '[remote] `shasum` and `md5sum` are still not found; bailing out'
      exit 1
    fi
  done
}
END
)

# The content of ~/.ssh.zsh/zsh/etc/zshenv on the remote machine.
local zshenv='
fpath=(${(@)fpath/#.\/run\//$HOME/.ssh.zsh/zsh/})
cd -- "$_zsh_orig_pwd"
export LD_LIBRARY_PATH=$_zsh_orig_ldpath
unset _zsh_orig_ldpath _zsh_orig_pwd'

# The content of ~/.ssh.zsh/zsh/zsh on the remote machine.
local zsh='#!/bin/sh
export _zsh_orig_pwd=$PWD
export _zsh_orig_ldpath=$LD_LIBRARY_PATH
cd -- "$HOME"/.ssh.zsh/zsh || exit
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/.ssh.zsh/zsh" exec ./zsh-portable "$@"'

print -ru2 -- '[local] connecting: ssh'  "$@"

# Rock 'n roll!
ssh -t "$@" '
  set -o pipefail 2>/dev/null
  '"${(@)required_tools/(#m)*/${check_tool//TOOL/$MATCH}}"'
  '$fetch_init'
  '$checksum_init'
  if ! command -v zsh >/dev/null 2>&1; then
    dir="$HOME"/.ssh.zsh/zsh
    if [ ! -e "$dir" ]; then
      >&2 echo "[remote] installing zsh"
      rm -rf -- "$dir".tmp                                  || exit
      mkdir -p -- "$dir".tmp                                || exit
      kernel=$(uname -s)                                    || exit
      arch=$(uname -m)                                      || exit
      fetch_init                                            || exit
      $(echo $fetch) "'$zsh_url'" | tar -C "$dir".tmp -pxz  || exit
      ln -s -- . "$dir".tmp/run                             || exit
      mkdir -p -- "$dir".tmp/etc                            || exit
      >"$dir".tmp/etc/zshenv printf "%s" '${(q)zshenv}'     || exit
      rm -- "$dir".tmp/zsh.sh                               || exit
      mv -- "$dir".tmp/zsh "$dir".tmp/zsh-portable          || exit
      >"$dir".tmp/zsh printf "%s" '${(q)zsh}'               || exit
      chmod +x "$dir".tmp/zsh                               || exit
      mv -- "$dir".tmp "$dir"                               || exit
    fi
    export PATH="$PATH:$dir"
  fi
  dump='${(q)dump}'
  if [ -n "$dump" ]; then
    printf "%s" "$dump" | base64 -d | tar -C ~ -pxz         || exit
  fi
  if [ ! -e ~/.zshrc ]; then
    >&2 echo "[remote] installing zshrc"
    fetch_init                                              || exit
    >~/.zshrc.tmp $(echo $fetch) '${(q)zshrc_url}'          || exit
    if ! command -v git >/dev/null 2>&1; then
      dir="$HOME"/.ssh.zsh/git
      if [ ! -e "$dir" ]; then
        >&2 echo "[remote] installing git"
        rm -rf -- "$dir".tmp                                || exit
        mkdir -p -- "$dir".tmp                              || exit
        arch=$(uname -m)                                    || exit
        fetch_init                                          || exit
        checksum_init                                       || exit
        set -x
        (
          cd -- "$dir".tmp                                  || exit
          archive="'${git_url:t}'"
          >"$archive" $(echo $fetch) "'$git_url'"           || exit
          sum=$($(echo $checksum) "$archive")               || exit
          if echo "$checksum" | grep -F md5 >/dev/null; then
            url="'$git_md5_url'"
          else
            url="'$git_sha512_url'"
          fi
          $(echo $fetch) "$url" | grep -F "$sum" >/dev/null || exit
          <"$archive" tar -pxz                              || exit
          rm -- "$archive"                                  || exit
        )                                                   || exit
        mv -- "$dir".tmp "$dir"                             || exit
      fi
      export PATH="$PATH:$dir/usr/bin"
      sed "s/ --recurse-submodules -j 8//g" -i ~/.zshrc.tmp || exit
      sed "s/https:/git:/g" -i ~/.zshrc.tmp                 || exit
    fi
    mv -- ~/.zshrc.tmp ~/.zshrc                             || exit
  fi
  >&2 echo "[remote] starting zsh"
  exec zsh -il'