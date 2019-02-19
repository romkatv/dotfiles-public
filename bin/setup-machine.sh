#!/bin/bash

set -xueE -o pipefail

readonly WSL=$(grep -q Microsoft /proc/version && echo 1 || echo 0)

PACKAGES=(
  ascii
  build-essential
  clang-format
  curl
  dos2unix
  g++-8
  gawk
  gedit
  git
  jq
  libgmp-dev
  libxml2-utils
  mc
  meld
  nano
  p7zip-full
  p7zip-rar
  python-pip
  unoconv
  unrar
  wget
  xsel
  zlib1g-dev
  zsh
)

if [[ "$WSL" == 1 ]]; then
  PACKAGES+=(ubuntu-gnome-desktop)
else
  PACKAGES+=(gnome-tweak-tool)
fi

sudo apt update
sudo apt install -y "${PACKAGES[@]}"

if ! test -d "$HOME"/.oh-my-zsh; then
  sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

if ! test -d "$HOME"/.oh-my-zsh/custom/plugins/zsh-autosuggestions; then
  git clone                                               \
    https://github.com/zsh-users/zsh-autosuggestions.git  \
    "$HOME"/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

if ! test -d "$HOME"/.oh-my-zsh/custom/themes/powerlevel9k; then
  git clone                                       \
    https://github.com/bhilburn/powerlevel9k.git  \
    "$HOME"/.oh-my-zsh/custom/themes/powerlevel9k
fi

if [[ "$WSL" == 0 ]]; then
  gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS Nerd Font Mono 11'
  # Avoid clock snafu when dual-booting Windows and Linux.
  # See https://www.howtogeek.com/323390/how-to-fix-windows-and-linux-showing-different-times-when-dual-booting/.
  timedatectl set-local-rtc 1 --adjust-system-clock
  if ! grep -qF '# My custom crap' /etc/fstab; then
    sudo bash -c '
      echo "# My custom crap" >>/etc/fstab
      echo "tmpfs /dev/shm tmpfs defaults,rw,nosuid,nodev,size=64g 0 0" >>/etc/fstab
    '
  fi
  if ! test -f /usr/bin/code; then
    VSCODE_DEB=$(mktemp)
    curl -L 'https://go.microsoft.com/fwlink/?LinkID=760868' >"$VSCODE_DEB"
    sudo apt install "$VSCODE_DEB"
    rm "$VSCODE_DEB"
  fi
fi
