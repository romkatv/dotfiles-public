#!/bin/bash
#
# Sets up environment. Must be run after bootstrap-dotfiles.sh. Can be run multiple times;
# it won't do things that have already been done.

set -xueE -o pipefail

# '1' if running under Windows Subsystem for Linux, '0' otherwise.
readonly WSL=$(grep -q Microsoft /proc/version && echo 1 || echo 0)

# Install a bunch of debian packages.
function install_packages() {
  local PACKAGES=(
    ascii
    build-essential
    clang-format
    command-not-found
    curl
    dos2unix
    g++-8
    gawk
    gedit
    git
    jq
    meld
    nano
    p7zip-full
    p7zip-rar
    unoconv
    unrar
    wget
    x11-xserver-utils
    xsel
    zsh
  )

  if [[ "$WSL" == 1 ]]; then
    PACKAGES+=(ubuntu-gnome-desktop)
  else
    PACKAGES+=(gnome-tweak-tool)
  fi

  sudo apt update
  sudo apt install -y "${PACKAGES[@]}"
}

# Install oh-my-zsh
function install_ohmyzsh() {
  test ! -d "$HOME"/.oh-my-zsh || return 0
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

# Install oh-my-zsh plugin or theme.
function install_ohmyzsh_extension() {
  test ! -d "$HOME/.oh-my-zsh/custom/${1}s/$2" || return 0
  git clone "$3" "$HOME/.oh-my-zsh/custom/${1}s/$2"
}

# Install Visual Studio Code.
function install_vscode() {
  test $WSL -eq 0 || return 0
  test ! -f /usr/bin/code || return 0
  local VSCODE_DEB=$(mktemp)
  curl -L 'https://go.microsoft.com/fwlink/?LinkID=760868' >"$VSCODE_DEB"
  sudo apt install "$VSCODE_DEB"
  rm "$VSCODE_DEB"
}

# Avoid clock snafu when dual-booting Windows and Linux.
# See https://www.howtogeek.com/323390/how-to-fix-windows-and-linux-showing-different-times-when-dual-booting/.
function fix_clock() {
  test $WSL -eq 0 || return 0
  timedatectl set-local-rtc 1 --adjust-system-clock
}

# Set the shared memory size limit to 64GB (the default is 32GB).
function fix_shm() {
  test $WSL -eq 0 || return 0
  ! grep -qF '# My custom crap' /etc/fstab || return 0
  sudo bash -c '
    echo "# My custom crap" >>/etc/fstab
    echo "tmpfs /dev/shm tmpfs defaults,rw,nosuid,nodev,size=64g 0 0" >>/etc/fstab
  '
}

# Install decent monospace font.
function install_font() {
  if [[ $WSL == 1 ]]; then
    local fontdir="$HOME/.local/share/fonts/NerdFonts"
    local font="Meslo LG L DZ Regular Nerd Font Complete Mono Windows Compatible.ttf"
    local reg="register-cmd-font.reg"
    local tmpdir
    tmpdir=$(wslpath $(cmd.exe /c "echo %TMP%" | sed 's/\r$//'))
    cp -f "$fontdir/$font" "$fontdir/$reg" "$tmpdir/"
    # This will open the font in a separate window where the user must click "Install".
    cmd.exe /C "$(wslpath -w "$tmpdir/$font")"
    # This will ask the user for permissions to modify registry.
    cmd.exe /C "$(wslpath -w "$tmpdir/$reg")"
    # If everything went well, the font will appear in the list of True Type fonts
    # in Windows Command Prompt' Properties after a reboot. The user will have to
    # manually switch to "MesloLGLDZ NF" there.
  else
    gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS Nerd Font Mono 11'
  fi
}

install_packages
install_vscode
install_font
install_ohmyzsh

install_ohmyzsh_extension plugin \
  zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
install_ohmyzsh_extension theme \
  powerlevel9k https://github.com/bhilburn/powerlevel9k.git

fix_clock
fix_shm

echo SUCCESS
