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
cursor-shape='ibeam'
use-custom-command=false
use-theme-colors=false
exit-action='close'
terminal-bell='none'
use-system-font=true
scrollback-lines=1000000

[/]
quake-specific-monitor=0
accelerators-enabled=true
unsafe-paste-alert=false
tab-position='top'
use-overlay-scrollbar=false
sidebar-on-right=false
terminal-title-style='none'
theme-variant='dark'
session-name='\${title}'
use-tabs=true
new-instance-mode='new-window'
enable-wide-handle=true
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

if [[ "$(</proc/version)" == *[Mm]icrosoft* ]] 2>/dev/null; then
  readonly WSL=1
else
  readonly WSL=0
fi

# Install a bunch of debian packages.
function install_packages() {
  local packages=(
    ascii
    apt-transport-https
    autoconf
    bfs
    bsdutils
    bzip2
    build-essential
    ca-certificates
    clang-format
    cmake
    command-not-found
    curl
    dconf-cli
    dos2unix
    g++
    gawk
    gedit
    git
    gnome-icon-theme
    gzip
    htop
    jsonnet
    jq
    lftp
    libglpk-dev
    libncurses-dev
    libxml2-utils
    man
    meld
    moreutils
    nano
    openssh-server
    p7zip-full
    p7zip-rar
    perl
    python3
    python3-pip
    pigz
    software-properties-common
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
    packages+=(gnome-tweak-tool imagemagick iotop tilix remmina wireguard docker.io)
  fi

  sudo apt-get update
  sudo bash -c 'DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::options::=--force-confdef -o DPkg::options::=--force-confold upgrade -y'
  sudo apt-get install -y "${packages[@]}"
  sudo apt-get autoremove -y
  sudo apt-get autoclean
}

function install_b2() {
  sudo pip3 install --upgrade b2
}

function install_docker() {
  if (( WSL )); then
    local release
    release="$(lsb_release -cs)"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu
      $release
      stable"
    sudo apt-get update -y
    sudo apt-get install -y docker-ce
  else
    sudo apt-get install -y docker.io
  fi
  sudo usermod -aG docker "$USER"
  pip3 install --user docker-compose
}

function install_brew() {
  local install
  install="$(mktemp)"
  curl -fsSLo "$install" https://raw.githubusercontent.com/Homebrew/install/master/install.sh
  bash -- "$install" </dev/null
  rm -- "$install"
}

# Install Visual Studio Code.
function install_vscode() {
  (( !WSL )) || return 0
  ! command -v code &>/dev/null || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL 'https://go.microsoft.com/fwlink/?LinkID=760868' >"$deb"
  sudo dpkg -i "$deb"
  rm -- "$deb"
}

function install_exa() {
  local v="0.9.0"
  ! command -v exa &>/dev/null || [[ "$(exa --version)" != *" v$v" ]] || return 0
  local tmp
  tmp="$(mktemp -d)"
  pushd -- "$tmp"
  curl -fsSLO "https://github.com/ogham/exa/releases/download/v${v}/exa-linux-x86_64-${v}.zip"
  unzip exa-linux-x86_64-${v}.zip
  sudo install -DT ./exa-linux-x86_64 /usr/local/bin/exa
  popd
  rm -rf -- "$tmp"
}

function install_ripgrep() {
  local v="12.1.1"
  ! command -v rg &>/dev/null || [[ "$(rg --version)" != *" $v "* ]] || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${v}/ripgrep_${v}_amd64.deb" >"$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function install_jc() {
  local v="1.13.4"
  ! command -v jc &>/dev/null || [[ "$(jc -a | jq -r .version)" != "$v" ]] || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL "https://jc-packages.s3-us-west-1.amazonaws.com/jc-${v}-1.x86_64.deb" >"$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function install_bat() {
  local v="0.17.1"
  ! command -v bat &>/dev/null || [[ "$(bat --version)" != *" $v" ]] || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL "https://github.com/sharkdp/bat/releases/download/v${v}/bat_${v}_amd64.deb" > "$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function install_gh() {
  local v="1.6.2"
  ! command -v gh &>/dev/null || [[ "$(gh --version)" != */v"$v" ]] || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSL "https://github.com/cli/cli/releases/download/v${v}/gh_${v}_linux_amd64.deb" > "$deb"
  sudo dpkg -i "$deb"
  rm "$deb"
}

function fix_locale() {
  sudo tee /etc/default/locale >/dev/null <<<'LC_ALL="C.UTF-8"'
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
  sudo mkdir -p /mnt/c /mnt/d
  sudo tee -a /etc/fstab >/dev/null <<<'# My custom crap
tmpfs /dev/shm tmpfs defaults,rw,nosuid,nodev,size=64g 0 0
UUID=F212115212111D63 /mnt/c ntfs-3g nosuid,nodev,uid=0,gid=0,noatime,streams_interface=none,remove_hiberfile,async,lazytime,big_writes 0 0
UUID=2A680BF9680BC315 /mnt/d ntfs-3g nosuid,nodev,uid=0,gid=0,noatime,streams_interface=none,remove_hiberfile,async,lazytime,big_writes 0 0'
}

function win_install_fonts() {
  local dst_dir
  dst_dir="$(cmd.exe /c 'echo %LOCALAPPDATA%\Microsoft\Windows\Fonts' 2>/dev/null | sed 's/\r$//')"
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
  (( WSL )) || return 0
  win_install_fonts ~/.local/share/fonts/NerdFonts/*.ttf
}

function add_to_sudoers() {
  # This is to be able to create /etc/sudoers.d/"$username".
  if [[ "$USER" == *'~' || "$USER" == *.* ]]; then
    >&2 echo "$BASH_SOURCE: invalid username: $USER"
    exit 1
  fi

  sudo usermod -aG sudo "$USER"
  sudo tee /etc/sudoers.d/"$USER" <<<"$USER ALL=(ALL) NOPASSWD:ALL" >/dev/null
  sudo chmod 440 /etc/sudoers.d/"$USER"
}

function fix_dbus() {
  (( WSL )) || return 0
  sudo dbus-uuidgen --ensure
}

function patch_ssh() {
  local v='8.2p1-4ubuntu0.1'
  local ssh
  ssh="$(which ssh)"
  grep -qF -- 'Warning: Permanently added' "$ssh" || return 0
  dpkg -s openssh-client | grep -qxF "Version: 1:$v" || return 0
  local deb
  deb="$(mktemp)"
  curl -fsSLo "$deb" \
    "https://github.com/romkatv/ssh/releases/download/v1.0/openssh-client_${v}_amd64.deb"
  sudo dpkg -i "$deb"
  rm -- "$deb"
}

function enable_sshd() {
  sudo tee /etc/ssh/sshd_config >/dev/null <<\END
ClientAliveInterval 60
AcceptEnv TERM
X11Forwarding no
X11UseLocalhost no
PermitRootLogin no
AllowTcpForwarding no
AllowAgentForwarding no
AllowStreamLocalForwarding no
AuthenticationMethods publickey
PrintLastLog no
PrintMotd no
END
  (( !WSL )) || return 0
  sudo systemctl enable --now ssh
  if [[ ! -e ~/.ssh/authorized_keys ]]; then
    cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
  fi
}

# Increase imagemagic memory and disk limits.
function fix_imagemagic() {
  # TODO: enable this.
  return
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

add_to_sudoers

install_packages
install_docker
install_brew
install_b2
install_vscode
install_ripgrep
install_jc
install_bat
install_gh
install_exa
# install_fonts

patch_ssh
enable_sshd
disable_motd_news

fix_locale
fix_clock
fix_shm
fix_dbus
fix_imagemagic

set_preferences

echo SUCCESS
