## Installation

### Github Setup
This needs to be done once per user.

#### Set up dotfiles-public repo.
- Go to https://github.com/romkatv/dotfiles-public and click *Fork*.
- Replace "romkatv" and "roman.perepelitsa@gmail.com" in `.gitconfig` of the newly created fork with your own data. You can do it thrugh the GitHub web UI.

#### Set up dotfiles-private repo.
- Go to https://github.com/new and create an empty `dotfiles-private` repo. Make it private.
- Open the newly created repo in GitHub UI and click *Create new file*.
  - Name: `.ssh/config`.
  - Content:
```text
Host *
  ServerAliveInterval 60
  AddKeysToAgent yes
```
- Click *Commit new file* at the bottom.

#### Set up ssh keys.
- Generate a pair of ssh keys -- `rsa_id` and `rsa_id.pub` -- and add `rsa_id.pub` to github.com. See https://help.github.com/en/articles/connecting-to-github-with-ssh for details. Use a strong passphrase.
- Backup `rsa_id` in a secure persistent storage system. For example, in your password manager.

### Windows Setup

#### Windows Preparation
This needs to be done once per Windows installation. You don't need to repeat these steps when reinstalling Ubuntu.

- Install *Notepad++* from https://notepad-plus-plus.org/.
- Install *VcXsrv* from https://sourceforge.net/projects/vcxsrv/.
- Run *Start > XLaunch*.
  - Click *Next*.
  - Click *Next*.
  - Uncheck *Primary Selection*. Click *Next*.
  - Click *Save Configuration* and save `config.xlaunch` in your `Startup` folder at `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`.
  - Click *Finish*.
- Open *PowerShell* as *Administrator* and run:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```
- Reboot if prompted.
- Go to https://www.microsoft.com/store/p/ubuntu/9nblggh4msv6 and install *Ubuntu* app.

#### WSL Removal
Follow these steps to remove your *Ubuntu* distribution with all files (applications, settings, home directory, etc.). You can recreate *Ubuntu* by following [WSL Installation](#wsl-installation) guide below.

- Delete your current *Ubuntu* installation by running the following command in *PowerShell*:
```powershell
wslconfig.exe /unregister Ubuntu
```

#### WSL Installation
These steps allow you to recreate the whole WSL environment. Before proceeding, delete the current *Ubuntu* installation if you have it. See [WSL Removal](#wsl-removal).

- Download `id_rsa` into the Windows `Downloads` folder. It's OK if it's downloaded as `id_rsa.txt`.
- Click *Start > Ubuntu*. If you get an error, remove *Ubuntu* app via *Add or remove programs*, go to https://www.microsoft.com/store/p/ubuntu/9nblggh4msv6 and install *Ubuntu* app. Once *Start > Ubuntu* is working, create a new user.
- Type this (you might need to change the value of `GITHUB_USERNAME`):
```bash
GITHUB_USERNAME=$USER bash -c \
  "$(curl -fsSL 'https://raw.githubusercontent.com/romkatv/dotfiles-public/master/bin/bootstrap-machine.sh')"
```
- Say `Yes` when prompted to terminate WSL.

#### Windows Configuration
These steps need to be done once per Windows installation. You don't need to repeat them after reinstalling Ubuntu.

- Click *Start > Ubuntu*.
- Pin *Ubuntu* to taskbar.
- Position and resize the window to your liking.
- Open *Properties* in the menu of *Ubuntu* and make the following changes:
  - Tab *Options*:
    - Check *Quick Edit Mode*, *Use Ctrl+Shift+C/V as Copy/Paste*, *Enable line wrapping selection* and *Extended text selection keys*.
    - Uncheck the rest.
  - Tab *Font*:
    - Set font to *MesloLGS NF*.
    - Set *Size* to 20.
  - Tab *Layout*:
    - Set *Screen Buffer Size > Height* to 9999.
    - Check *Wrap text output on resize*.
    - Uncheck *Let system position window*.
  - Tab *Terminal*:
    - Set *Cursor Shape* to *Solid Box*.
    - Check *Disable Scroll-Forward*.

### Maintenance
Run this command occasionally.

```zsh
sync-dotfiles && bash ~/bin/setup-machine.sh && exec zsh #maintenance
```

Pro tip: Copy-paste this whole command including the comment. Next time when you decide to run maintenance tasks, press `Ctrl+R` and type `#maintenance`. This is how you can "tag" commands and easily find them later. You can apply more than one "tag". Technically, everything after `#` is a comment.
