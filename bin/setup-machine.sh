#!/bin/bash
#
# Sets up environment. Must be run after bootstrap-dotfiles.sh. Can be run multiple times;
# it won't do things that have already been done.

set -xueE -o pipefail

# These are obtained by running 'dconf dump /org/gnome/gedit/preferences/'.
readonly GEDIT_PREFERENCES="[editor]
highlight-current-line=true
display-right-margin=true
display-overview-map=false
bracket-matching=true
tabs-size=uint32 2
display-line-numbers=true
insert-spaces=true
right-margin-position=uint32 100
background-pattern='none'
wrap-last-split-mode='word'
auto-indent=true

[ui]
show-tabs-mode='auto'
side-panel-visible=true"

# '1' if running under Windows Subsystem for Linux, '0' otherwise.
readonly WSL=$(grep -q Microsoft /proc/version && echo 1 || echo 0)

# Install a bunch of debian packages.
function install_packages() {
  local PACKAGES=(
    ascii
    bzip2
    build-essential
    clang-format
    command-not-found
    curl
    dconf-cli
    dos2unix
    g++-8
    gawk
    gedit
    git
    gunzip
    gzip
    htop
    jq
    libxml2-utils
    meld
    nano
    p7zip-full
    p7zip-rar
    perl
    pigz
    tree
    unrar
    unzip
    wget
    x11-utils
    xsel
    xz-utils
    zsh
  )

  if [[ "$WSL" == 1 ]]; then
    PACKAGES+=(dbus-x11)
  else
    PACKAGES+=(gnome-tweak-tool iotop)
  fi

  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y "${PACKAGES[@]}"
  sudo apt autoremove -y
}

# If this user's login shell is not already "zsh", attempt to switch.
function change_shell() {
  test "${SHELL##*/}" != "zsh" || return 0
  chsh -s "$(grep -E '/zsh$' /etc/shells | tail -1)"
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

function install_ripgrep() {
  local deb="$(mktemp)"
  curl -fsSL 'https://github.com/BurntSushi/ripgrep/releases/download/11.0.1/ripgrep_11.0.1_amd64.deb' > "$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function install_fzf() {
  ~/dotfiles/fzf/install --bin
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

function win_install_fonts() {
  local dst_dir
  dst_dir=$(wslpath $(cmd.exe /c "echo %LOCALAPPDATA%\Microsoft\\Windows\\Fonts" 2>/dev/null | sed 's/\r$//'))
  mkdir -p "$dst_dir"
  local src
  for src in "$@"; do
    local file=$(basename "$src")
    if [[ ! -f "$dst_dir/$file" ]]; then
      cp -f "$src" "$dst_dir/"
    fi
    local win_path
    win_path=$(wslpath -w "$dst_dir/$file")
    # Install font for the current user. It'll appear in "Font settings".
    reg.exe add \
      "HKCU\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" \
      /v "${file%.*} (TrueType)"  /t REG_SZ /d "$win_path" /f 2>/dev/null
  done
}

# Install a decent monospace font.
function install_fonts() {
  if [[ $WSL == 1 ]]; then
    win_install_fonts "$HOME"/.local/share/fonts/NerdFonts/*.ttf
  fi
}

function fix_dbus() {
  test $WSL -eq 1 || return 0
  sudo dbus-uuidgen --ensure
}

function fix_gcc() {
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8
}

function with_dbus() {
  [[ -z "${DBUS_SESSION_BUS_ADDRESS+X}" ]] && set -- dbus-launch "$@"
  "$@"
}

# Set preferences for various applications.
function set_preferences() {
  if [[ $WSL == 0 ]]; then
    # It doesn't work on WSL.
    gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS NF 11'
  fi
  if [[ "${DISPLAY+X}" == "" ]]; then
    export DISPLAY=:0
  fi
  if ! xprop -root &>/dev/null; then
    # No X server at $DISPLAY.
    return
  fi
  with_dbus dconf load '/org/gnome/gedit/preferences/' <<<"$GEDIT_PREFERENCES"
}

if [[ "$(id -u)" == 0 ]]; then
  echo "setup-machine.sh: please run as non-root" >&2
  exit 1
fi

umask g-w,o-w

install_packages
install_vscode
install_ripgrep
install_fzf
install_fonts

fix_clock
fix_shm
fix_dbus
fix_gcc

set_preferences

change_shell

[[ -f "$HOME"/.z ]] || touch "$HOME"/.z

echo SUCCESS
