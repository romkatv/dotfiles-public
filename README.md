## Installation

### Github Setup

This needs to be done once per user.

#### Set up dotfiles-public repo.

- Go to https://github.com/romkatv/dotfiles-public and click *Fork*.
- Replace "romkatv" and "roman.perepelitsa@gmail.com" in `.gitconfig` of the newly created fork with your own data. You can do it thrugh the GitHub web UI.

#### Set up dotfiles-private repo.

- Go to https://github.com/new and create an empty `dotfiles-private` repo. Make it private.

#### Set up ssh keys.

- Generate a pair of ssh keys -- `rsa_id` and `rsa_id.pub` -- and add `rsa_id.pub` to github.com. See https://help.github.com/en/articles/connecting-to-github-with-ssh for details. Use a strong passphrase.
- Backup `rsa_id` in a secure persistent storage system. For example, in your password manager.

### Windows Setup

#### Windows Preparation

This needs to be done once per Windows installation. You don't need to repeat these steps when reinstalling Ubuntu.

- Open *PowerShell* as *Administrator* and run:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```
- Reboot if prompted.
- Install chocolatey from https://chocolatey.org/install.
- Open *PowerShell* as *Administrator* and run:
```powershell
choco.exe install -y microsoft-windows-terminal vcxsrv
```
- Run *Start > XLaunch*.
  - Click *Next*.
  - Click *Next*.
  - Uncheck *Primary Selection*. Click *Next*.
  - Click *Save Configuration* and save `config.xlaunch` in your `Startup` folder at `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`.
  - Click *Finish*.

Optional: if disk `D:` does not exist, make it an alias for `C:`. If you don't know why you might want this, then you don't need it.

- Open *PowerShell* as *Administrator* and run:
```powershell
if (!(Test-Path -Path "D:\")) {
  New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices" -Name "D:" -PropertyType String -Value \DosDevices\C:\ -Force
}
```
- Reboot.

#### WSL Removal

Follow these steps to remove your Linux distro with all files (applications, settings, home directory, etc.). You can recreate it by following [WSL Installation](#wsl-installation) guide below.

- Find out the name of your default distro by running the following command from *PowerShell*:
```powershell
wsl.exe --list
```
- Delete a distro:
```powershell
wsl.exe --unregister DISTRO
```

#### WSL Installation

These steps allow you to recreate the whole WSL environment. Before proceeding, delete the current distro if you have it. See [WSL Removal](#wsl-removal).

- Download `id_rsa` into the Windows `Downloads` folder. It's OK if it's downloaded as `id_rsa.txt`.
- Go to https://www.microsoft.com/en-us/p/ubuntu-2004-lts/9n6svws3rx71 and install *Ubuntu 20.04 LTS*.
- Click *Start > Ubuntu*. If you get an error, remove *Ubuntu* via *Add or remove programs* and install it again. Once *Start > Ubuntu* is working, create a new user.
- Type this (change the value of `GITHUB_USERNAME` if it's not the same as your WSL username):
```bash
GITHUB_USERNAME=$USER bash -c \
  "$(curl -fsSL 'https://raw.githubusercontent.com/romkatv/dotfiles-public/master/bin/bootstrap-machine.sh')"
```
- Say `Yes` when prompted to terminate WSL.
- Run *Start > Windows Terminal*.
  - Press <kbd>Ctrl+,</kbd>.
  - Replace the content of `settings.json` with [this](https://raw.githubusercontent.com/romkatv/dotfiles-public/master/dotfiles/microsoft-terminal-settings.json). Change "romkatv" to your WSL username.

#### Optional: Windows Defender Exclusion

- Run *Start > Windows Security*.
  - Click *Virus & threat protection*.
  - Click *Manage settings* under *Virus & threat protection settings*.
  - Click *Add or remove exclusions* under *Exclusions*.
  - Click *Add an exclusion > Folder*.
  - Select `%USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu20.04onWindows_79rhkp1fndgsc`.

### Maintenance

Run this command occasionally.

```zsh
sync-dotfiles && bash ~/bin/setup-machine.sh && z4h update #maintenance
```

Pro tip: Copy-paste this whole command including the comment. Next time when you decide to run maintenance tasks, press `Ctrl+R` and type `#maintenance`. This is how you can "tag" commands and easily find them later. You can apply more than one "tag". Technically, everything after `#` is a comment.
