<div align="center">

## Samuel’s Hyprland Setup

Personal Hyprland/CachyOS setup based on [43PR/dotfiles](https://github.com/43PR/dotfiles), with Samuel-specific defaults and a safer installer for existing configurations.

### Upstream

Original setup, screenshots, guides and support: [43PR/dotfiles](https://github.com/43PR/dotfiles)

### **[Features](#features)  -  [Keybinds](#most-used-keybinds)  -  [Installation](#installation)**

</div>

![](Wallpapers/Showcase/9.png)
![](Wallpapers/Showcase/hover-areas.png)
![](Wallpapers/Showcase/4.png)
![](Wallpapers/Showcase/2.png)

## Personal defaults

* Chromium as browser
* German keyboard layout
* Mouse sensitivity `0`
* Natural scrolling enabled on the touchpad
* Hardware-neutral Waybar GPU tooltip
* User paths adapted for `samuelm`
* Installer preserves the current login shell instead of forcing Zsh
* Existing symlinked configs are fully backed up and replaced safely instead of writing through the symlink target

## Features

* **Waybar** > volume controls, media controls, network, CPU/RAM/GPU and workspaces
* **Custom settings menu** > System info, Network, Bluetooth, Monitors and Sound
* **Custom wallpaper selector** > Awww + Quickshell
* **App launcher** > Rofi
* **Shell config + Starship** > installer keeps the existing login shell
* **Spotify + Spicetify theme**
* **Custom monochrome theme**
* **Hyprlock**
* **Wlogout**
* **Terminal:** Kitty
* **File manager:** Thunar

> All programs: [packages.txt](packages.txt)

## Most used keybinds

| Keybind                 | Action                    |
| -----------             | ------------------------- |
| `Super + T`             | Terminal                  |
| `Super + Q`             | Close active window       |
| `Super + 1, 2, 3..`     | Change workspaces         |
| `Super + Shift + 1, 2..`| Move window to workspace  |
| `Super + D`             | Application launcher      |
| `Super + E`             | File manager              |
| `Super + B`             | Browser                   |
| `Super + W`             | Wallpaper selector        |
| `Super + I`             | Settings menu             |
| `Super + O`             | Switch opacity            |
| `Super + V`             | Clipboard history         |
| `Super + F`             | Toggle fullscreen         |
| `Super + Space`         | Toggle floating window    |
| `Super + Shift + W`     | Toggle Waybar             |
| `Super + Tab`           | Lock screen               |
| `Super + Grave`         | Logout menu               |
| `Delete`                | Screenshot fullscreen     |
| `Shift + Delete`        | Screenshot area           |
| `Super + Mouse wheel`   | Zoom in/out               |

> All keybinds: [.config/hypr/keybinds.lua](.config/hypr/keybinds.lua)

## Installation

Target: Arch-compatible Linux such as CachyOS, Arch, EndeavourOS or Manjaro.

The installer backs up every config path it replaces into `~/.config-backups/<timestamp>/`. Symlinked config directories are dereferenced into the backup first, so external trees such as ML4W are not modified accidentally.

```bash
sudo pacman -S git
git clone https://github.com/Samuel-Mencke/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

After installation, log out and back into Hyprland.

> [!NOTE]
> The current login shell is preserved.
>
> Waybar GPU usage uses `nvtop` and `jq`.
>
> If the wallpaper picker cache causes problems, remove `~/.cache/quickshell/thumbs/`.
>
> Default programs and input settings are in `.config/hypr/hyprland.lua`.

## Credits

Based on [43PR/dotfiles](https://github.com/43PR/dotfiles). The upstream repository contains the original design, assets, guides and support links.
