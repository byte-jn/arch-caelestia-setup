# arch-setup

Scripts to bootstrap a fresh Arch Linux install with a [Caelestia](https://github.com/caelestia-dots/caelestia) (Hyprland dotfiles) desktop.

## What it does

[`caelestia-install.sh`](caelestia-install.sh) prepares the system and hands off to the official Caelestia CLI installer:

- Runs a full system upgrade (`pacman -Syu`)
- Bootstraps an AUR helper (`yay`) if none is found
- Detects and installs the NVIDIA driver (open kernel module) when an NVIDIA GPU is present
- Installs and enables a login manager (`greetd` + `tuigreet`)
- Installs `caelestia-cli` and runs `caelestia install`, which handles Hyprland, PipeWire, fonts, theming, networking, and Bluetooth itself via its `manifest.toml`

## Usage

Run as a normal user with sudo rights — **not** as root:

```bash
chmod +x caelestia-install.sh
./caelestia-install.sh
```

A reboot is recommended once the script finishes.

## Configuration

A few options are set at the top of the script:

| Variable | Values | Description |
|---|---|---|
| `LOGIN_MANAGER` | `greetd` \| `none` | Install greetd+tuigreet, or skip login manager setup |
| `FORCE_NVIDIA` | `yes` \| `no` \| `""` | Force NVIDIA driver install/skip, or auto-detect via `lspci` |
| `NONINTERACTIVE_AUR` | `true` \| `false` | Install AUR packages without PKGBUILD review (`--noconfirm`) |

## Requirements

- Arch Linux (or an Arch-based distro with `pacman`)
- A non-root user with sudo access

## License

[MIT](LICENSE)
