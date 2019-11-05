#!/bin/bash
#
# Sets up environment. Must be run after bootstrap-dotfiles.sh. Can be run multiple times.

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

# These are obtained by running 'dconf dump /org/gnome/meld/'.
readonly MELD_PREFERENCES="[/]
indent-width=2
highlight-current-line=true
folder-columns=[('size', true), ('modification time', true), ('permissions', true)]
show-line-numbers=true
wrap-mode='none'
vc-commit-margin=100
insert-spaces-instead-of-tabs=false
highlight-syntax=true
draw-spaces=['space', 'tab', 'nbsp', 'leading', 'text', 'trailing']"

readonly TILIX_PREFERENCES="[profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d]
foreground-color='#EEEEEEEEECEC'
rewrap-on-resize=true
visible-name='Default'
palette=['#000000', '#CC0000', '#4D9A05', '#C3A000', '#3464A3', '#754F7B', '#05979A', '#D3D6CF', '#545652', '#EF2828', '#89E234', '#FBE84F', '#729ECF', '#AC7EA8', '#34E2E2', '#EDEDEB']
bold-is-bright=false
default-size-columns=174
default-size-rows=45
show-scrollbar=false
use-system-font=true
use-custom-command=false
use-theme-colors=false
exit-action='close'
scrollback-lines=1000000

[/]
quake-specific-monitor=0
unsafe-paste-alert=false
tab-position='top'
use-overlay-scrollbar=false
sidebar-on-right=false
terminal-title-style='none'
theme-variant='dark'
session-name='\${title}'
use-tabs=true
new-instance-mode='new-window'
enable-wide-handle=false
app-title='\${activeTerminalTitle}'
quake-hide-headerbar=false
quake-window-position='top'
warn-vte-config-issue=false
control-click-titlebar=true
terminal-title-show-when-single=true
window-style='disable-csd-hide-toolbar'

[keybindings]
session-resize-terminal-left='<Shift>Left'
session-switch-to-terminal-down='disabled'
session-add-right='<Alt>r'
session-resize-terminal-up='<Shift>Up'
session-add-down='<Alt>d'
session-resize-terminal-down='<Shift>Down'
session-switch-to-terminal-right='disabled'
session-switch-to-terminal-up='disabled'
session-resize-terminal-right='<Shift>Right'
session-switch-to-terminal-left='disabled'"

# '1' if running under Windows Subsystem for Linux, '0' otherwise.
readonly WSL="$(grep -q Microsoft /proc/version && echo 1 || echo 0)"

# Install a bunch of debian packages.
function install_packages() {
  local packages=(
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
    gzip
    htop
    jq
    lftp
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
    zip
    zsh
  )

  if (( WSL )); then
    packages+=(dbus-x11)
  else
    packages+=(gnome-tweak-tool iotop tilix)
  fi

  sudo apt update
  sudo bash -c 'DEBIAN_FRONTEND=noninteractive apt -o DPkg::options::=--force-confdef -o DPkg::options::=--force-confold upgrade -y'
  sudo apt install -y "${packages[@]}"
  sudo apt autoremove -y
}

# If this user's login shell is not already "zsh", attempt to switch.
function change_shell() {
  [[ "$SHELL" != */zsh ]] || return 0
  chsh -s "$(grep -E '/zsh$' /etc/shells | tail -1)"
}

# Install Visual Studio Code.
function install_vscode() {
  (( !WSL )) || return 0
  ! command -v code &>/dev/null || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL 'https://go.microsoft.com/fwlink/?LinkID=760868' >"$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function install_ripgrep() {
  local v="11.0.2"
  ! command -v rg &>/dev/null || [[ "$(rg --version)" != *" $v "* ]] || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${v}/ripgrep_${v}_amd64.deb" >"$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function install_bat() {
  local v="0.12.1"
  ! command -v bat &>/dev/null || [[ "$(bat --version)" != *" $v" ]] || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL "https://github.com/sharkdp/bat/releases/download/v${v}/bat_${v}_amd64.deb" > "$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function install_fzf() {
  ~/dotfiles/fzf/install --bin
}

# Avoid clock snafu when dual-booting Windows and Linux.
# See https://www.howtogeek.com/323390/how-to-fix-windows-and-linux-showing-different-times-when-dual-booting/.
function fix_clock() {
  (( !WSL )) || return 0
  timedatectl set-local-rtc 1 --adjust-system-clock
}

# Set the shared memory size limit to 64GB (the default is 32GB).
function fix_shm() {
  (( !WSL )) || return 0
  ! grep -qF '# My custom crap' /etc/fstab || return 0
  sudo tee -a /etc/fstab >/dev/null <<<'# My custom crap
tmpfs /dev/shm tmpfs defaults,rw,nosuid,nodev,size=64g 0 0'
}

function win_install_fonts() {
  local dst_dir="$(cmd.exe /c 'echo %LOCALAPPDATA%\Microsoft\Windows\Fonts' 2>/dev/null | sed 's/\r$//')"
  dst_dir="$(wslpath "$dst_dir")"
  mkdir -p "$dst_dir"
  local src
  for src in "$@"; do
    local file="$(basename "$src")"
    if [[ ! -f "$dst_dir/$file" ]]; then
      cp -f "$src" "$dst_dir/"
    fi
    local win_path
    win_path="$(wslpath -w "$dst_dir/$file")"
    # Install font for the current user. It'll appear in "Font settings".
    reg.exe add                                                 \
      'HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' \
      /v "${file%.*} (TrueType)" /t REG_SZ /d "$win_path" /f 2>/dev/null
  done
}

# Install a decent monospace font.
function install_fonts() {
  (( !WSL )) || win_install_fonts ~/.local/share/fonts/NerdFonts/*.ttf
}

function install_clean_tmp() {
  sudo cp ~/bin/clean-tmp /usr/local/bin/clean-tmp-su
  sudo chmod 755 /usr/local/bin/clean-tmp-su
  sudo tee /etc/sudoers.d/"$USER" >/dev/null <<<"$USER ALL=(ALL) NOPASSWD: /usr/local/bin/clean-tmp-su"
  sudo chmod 440 /etc/sudoers.d/"$USER"
}

function fix_dbus() {
  (( WSL )) || return 0
  sudo dbus-uuidgen --ensure
}

function fix_gcc() {
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8
  sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8
}

function with_dbus() {
  if [[ -z "${DBUS_SESSION_BUS_ADDRESS+X}" ]]; then
    dbus-launch "$@"
  else
    "$@"
  fi
}

# Set preferences for various applications.
function set_preferences() {
  if (( !WSL )); then
    gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS NF 11'
    sudo update-alternatives --set x-terminal-emulator /usr/bin/tilix.wrapper
  fi
  if [[ -z "${DISPLAY+X}" ]]; then
    export DISPLAY=:0
  fi
  if xprop -root &>/dev/null; then
    # Have X server at $DISPLAY.
    with_dbus dconf load '/org/gnome/gedit/preferences/' <<<"$GEDIT_PREFERENCES"
    with_dbus dconf load '/org/gnome/meld/' <<<"$MELD_PREFERENCES"
    if (( !WSL )); then
      with_dbus dconf load '/com/gexperts/Tilix/' <<<"$TILIX_PREFERENCES"
    fi
  fi
}

if [[ "$(id -u)" == 0 ]]; then
  echo "$BASH_SOURCE: please run as non-root" >&2
  exit 1
fi

umask g-w,o-w

install_packages
install_vscode
install_ripgrep
install_bat
install_fzf
install_fonts
install_clean_tmp

fix_clock
fix_shm
fix_dbus
fix_gcc

set_preferences

change_shell

echo SUCCESS
