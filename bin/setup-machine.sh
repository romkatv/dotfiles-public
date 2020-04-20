#!/bin/bash
#
# Sets up environment. Must be run after bootstrap-dotfiles.sh. Can be run multiple times.

set -xueE -o pipefail

# These are obtained by running `dconf dump /org/gnome/gedit/preferences/`.
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

# These are obtained by running `dconf dump /org/gnome/meld/`.
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

# These are obtained by running `dconf dump /com/gexperts/Tilix/`.
# Colors are Tango Dark with custom background (#171A1B instead of #2E3436, twice as dark).
readonly TILIX_PREFERENCES="[profiles/2b7c4080-0ddd-46c5-8f23-563fd3ba789d]
foreground-color='#EEEEEC'
background-color='#171A1B'
rewrap-on-resize=true
visible-name='Default'
palette=['#2E3436', '#CC0000', '#4D9A05', '#C3A000', '#3464A3', '#754F7B', '#05979A', '#D3D6CF', '#545652', '#EF2828', '#89E234', '#FBE84F', '#729ECF', '#AC7EA8', '#34E2E2', '#EDEDEB']
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
session-add-right='<Alt>r'
session-add-down='<Alt>d'
terminal-page-down='<Primary><Shift>Page_Down'
terminal-page-up='<Primary><Shift>Page_Up'
session-resize-terminal-left='disabled'
session-switch-to-terminal-down='disabled'
session-resize-terminal-up='disabled'
session-resize-terminal-down='disabled'
session-switch-to-terminal-right='disabled'
win-reorder-next-session='disabled'
session-switch-to-terminal-up='disabled'
session-resize-terminal-right='disabled'
win-reorder-previous-session='disabled'
session-switch-to-terminal-left='disabled'"

# '1' if running under Windows Subsystem for Linux, '0' otherwise.
readonly WSL="$(grep -iq Microsoft /proc/version && echo 1 || echo 0)"

# Install a bunch of debian packages.
function install_packages() {
  local packages=(
    ascii
    autoconf
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
    libncurses-dev
    libxml2-utils
    man
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
    xclip
    xsel
    xz-utils
    yodl
    zip
    zsh
  )

  if (( WSL )); then
    packages+=(dbus-x11)
  else
    sudo add-apt-repository -y ppa:remmina-ppa-team/remmina-next
    sudo add-apt-repository -y ppa:wireguard/wireguard
    packages+=(gnome-tweak-tool imagemagick iotop tilix remmina wireguard)
  fi

  sudo apt-get update
  sudo bash -c 'DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::options::=--force-confdef -o DPkg::options::=--force-confold upgrade -y'
  sudo apt-get install -y "${packages[@]}"
  sudo apt-get autoremove -y
  sudo apt-get autoclean
}

# If this user's login shell is not already "zsh", attempt to switch.
function change_shell() {
  local current
  current="$(getent passwd $USER | cut -d: -f7)"
  local new=/usr/local/bin/zsh
  [[ -x "$new" ]] || new=/bin/zsh
  [[ -x "$new" ]]

  [[ "$current" != "$new" ]] || return 0
  chsh -s "$new" || chsh -s "$new" || chsh -s "$new" || return
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

function install_zsh() {
  local v="g3b83246"
  if [[ -x /usr/local/bin/zsh ]]; then
    [[ "$(/usr/local/bin/zsh -c 'echo $ZSH_PATCHLEVEL')" != *-"$v" ]] || return 0
  fi
  local repo
  tmp="$(mktemp -d)"
  git clone 'https://github.com/romkatv/zsh.git' "$tmp"
  pushd "$tmp"
  git checkout "$v"
  ./Util/preconfig
  ./configure
  sudo make -j 20 install
  popd
  sudo rm -rf "$tmp"
  if ! grep -qE '^/usr/local/bin/zsh$' /etc/shells; then
    sudo tee -a /etc/shells <<</usr/local/bin/zsh >/dev/null
  fi
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
  (( WSL )) || return 0
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

# Increase imagemagic memory and disk limits.
function fix_imagemagic() {
  (( !WSL )) || return 0
  local cfg=/etc/ImageMagick-6/policy.xml k v kv
  [[ -f "$cfg" ]]
  for kv in "memory 16GiB" "map 32GiB" "width 128KP" "height 128KP" "area 8GiB" "disk 64GiB"; do
    read k v <<<"$kv"
    grep -qE 'name="'$k'" value="[^"]*"' "$cfg"
    sudo sed -i 's/name="'$k'" value="[^"]*"/name="'$k'" value="'$v'"/' "$cfg"
  done
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

function disable_motd_news() {
  (( !WSL )) || return 0
  sudo systemctl disable motd-news.timer
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

disable_motd_news

fix_clock
fix_shm
fix_dbus
fix_gcc
fix_imagemagic

set_preferences

install_zsh
change_shell

echo SUCCESS
