#!/usr/bin/env zsh
#
# Usage: ssh.zsh [ssh-options] [user@]hostname

emulate zsh -o pipefail -o extended_glob

# If there is no zsh on the remote machine, install this version to ~/.ssh.zsh/zsh.
local zsh_url='https://github.com/romkatv/zsh-bin/releases/download/v2.0.0/zsh-5.8-${kernel}-${arch}-static.tar.gz'
# If there is no `git` on the remove machine, install this version to ~/.ssh.zsh/git.
local git_url='http://s.minos.io/archive/bifrost/${arch}/git-2.7.2-2.tar.gz'
# md5 of @git_url; not using http://s.minos.io/archive/bifrost/x86_64/md5sum.txt because it's http.
local git_md5='4151ed3bf2602dc7125ccddc65235af7'
# sha512 of @git_url.
local git_sha512='1d67b643d79f8426ddf7ee799a6bcb92389b534eb39378d6ba67af1202d77a3391dc69a0f0be801773fcd442cae9365d31965071a66d466bdbbd9e37b8441b11'
# If there is no ~/.zshrc on the remote machine, download this.
local zshrc_url='https://raw.githubusercontent.com/romkatv/zsh4humans/c7c1a534a79c6537c68a651ab75540459dfa9798/.zshrc'

# Require these tools to be installed on the remote machine.
local required_tools=(uname mkdir rm mv chmod ln tar base64 sed tr)

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
  set -x
  set -o pipefail 2>/dev/null
  '"${(@)required_tools/(#m)*/${check_tool//TOOL/$MATCH}}"'
  '$fetch_init'
  '$checksum_init'
  dir="${XDG_CACHE_HOME:-$HOME/.cache}"/.ssh.zsh
  mkdir -p -- $dir || exit
  if ! command -v zsh >/dev/null 2>&1; then
    if [ ! -e "$dir/zsh" ]; then
      >&2 echo "[remote] installing zsh"
      kernel=$(uname -s)                                    || exit
      kernel=$(printf "%s" "$kernel" | tr "[A-Z]" "[a-z]")  || exit
      arch=$(uname -m)                                      || exit
      arch=$(printf "%s" "$arch" | tr "[A-Z]" "[a-z]")      || exit
      tmp="$dir/zsh-5.8-${kernel}-${arch}-static"
      rm -rf -- "$tmp"                                      || exit
      fetch_init                                            || exit
      $(echo $fetch) "'$zsh_url'" | tar -C "$dir" -pxz      || exit
      "$tmp/share/zsh/5.8/scripts/relocate" "$dir/zsh"      || exit
      mv -- "$tmp" "$dir"/zsh                               || exit
    fi
    export PATH="$PATH:$dir/zsh/bin"
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
      if [ ! -e "$dir"/git ]; then
        >&2 echo "[remote] installing git"
        rm -rf -- "$dir"/git.tmp                            || exit
        mkdir -p -- "$dir"/git.tmp                          || exit
        arch=$(uname -m)                                    || exit
        arch=$(printf "%s" "$arch" | tr "[A-Z]" "[a-z]")    || exit
        fetch_init                                          || exit
        checksum_init                                       || exit
        archive="$dir"/git.tmp/archive
        >"$archive" $(echo $fetch) "'$git_url'"             || exit
        sum=$($(echo $checksum) - <"$archive")              || exit
        if [ "$sum" != "'$git_md5'  -" ]; then
          [ "$sum" = "'$git_sha512'  -" ]                   || exit
        fi
        tar -C "$dir"/git.tmp -pxz <"$archive"              || exit
        rm -- "$archive"                                    || exit
        mv -- "$dir"/git.tmp "$dir"/git                     || exit
      fi
      export PATH="$PATH:$dir/git/usr/bin"
      sed "s/ --recurse-submodules -j 8//g" -i ~/.zshrc.tmp || exit
      sed "s/https:/git:/g" -i ~/.zshrc.tmp                 || exit
    fi
    mv -- ~/.zshrc.tmp ~/.zshrc                             || exit
  fi
  >&2 echo "[remote] starting zsh"
  exec zsh -il'
