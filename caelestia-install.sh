#!/usr/bin/env bash
#
# caelestia-install.sh
# Bereitet Arch Linux für Caelestia (Hyprland-Dotfiles) vor und startet die
# offizielle CLI-Installation. Übernimmt AUR-Helper-Bootstrap, NVIDIA-Treiber
# und Login-Manager (greetd+tuigreet) — alles andere (Hyprland, PipeWire,
# Fonts, Theming, Netzwerk, Bluetooth) installiert `caelestia install` selbst
# über das offizielle manifest.toml.
#
# Quelle: https://github.com/caelestia-dots/caelestia
#
# Ausführung:
#   chmod +x caelestia-install.sh
#   ./caelestia-install.sh
#
# Als normaler Benutzer mit sudo-Rechten ausführen, nicht als root.

set -euo pipefail

### Konfiguration ###
LOGIN_MANAGER="greetd"    # greetd | none (Caelestia liefert selbst keinen Login-Manager)
FORCE_NVIDIA=""            # "yes" | "no" | "" (Autoerkennung via lspci)
NONINTERACTIVE_AUR=false  # true = AUR-Installation ohne PKGBUILD-Review (--noconfirm)

### Logging ###
log()  { printf '\033[1;32m[+]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m[-]\033[0m %s\n' "$1" >&2; }

### Vorprüfungen ###
[[ $EUID -eq 0 ]] && { err "Nicht als root ausführen."; exit 1; }
command -v pacman >/dev/null || { err "Kein Arch-basiertes System."; exit 1; }
sudo -v

pkg() { sudo pacman -S --needed --noconfirm "$@"; }

multilib_enabled() {
  pacman-conf --repo-list 2>/dev/null | grep -qx multilib
}

full_upgrade() {
  log "Vollständiges Systemupdate"
  sudo pacman -Syu --noconfirm
}

### AUR-Helper ###

detect_aur_helper() {
  if command -v yay >/dev/null; then echo yay
  elif command -v paru >/dev/null; then echo paru
  else echo ""
  fi
}

bootstrap_yay() {
  log "Kein AUR-Helper gefunden, baue yay"
  pkg base-devel git
  local tmp
  tmp=$(mktemp -d)
  git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  echo yay
}

aur_install() {
  local helper="$1"; shift
  if [[ "$NONINTERACTIVE_AUR" == true ]]; then
    "$helper" -S --needed --noconfirm "$@"
  else
    "$helper" -S --needed "$@"
  fi
}

### NVIDIA (gleiche Logik wie beim KDE-Setup) ###

install_gpu_driver() {
  local vendor
  vendor=$(lspci -k 2>/dev/null | grep -Ei 'VGA|3D controller' | grep -Eio 'NVIDIA' | head -n1 || true)

  if [[ "$FORCE_NVIDIA" == "no" ]]; then
    log "NVIDIA-Treiber übersprungen (FORCE_NVIDIA=no)"
    return 0
  fi

  if [[ -z "$vendor" && "$FORCE_NVIDIA" != "yes" ]]; then
    log "Keine NVIDIA-GPU erkannt, überspringe proprietären Treiber"
    return 0
  fi

  local kernel_pkg driver_pkg
  kernel_pkg=$(pacman -Qq 2>/dev/null | grep -E '^linux(-lts|-zen|-hardened|-rt)?$' | head -n1)

  if [[ -z "$kernel_pkg" ]]; then
    warn "Kernel-Paket nicht erkannt. NVIDIA-Treiber manuell installieren."
    return 0
  fi

  case "$kernel_pkg" in
    linux)      driver_pkg="nvidia-open" ;;
    linux-lts)  driver_pkg="nvidia-open-lts" ;;
    *)          driver_pkg="nvidia-open-dkms"
                pkg "${kernel_pkg}-headers" ;;
  esac

  log "NVIDIA-Treiber: $driver_pkg (Kernel: $kernel_pkg)"
  pkg "$driver_pkg" nvidia-utils nvidia-settings

  if multilib_enabled; then
    pkg lib32-nvidia-utils
  else
    warn "multilib nicht aktiviert – lib32-nvidia-utils übersprungen"
  fi

  warn "Für Wayland ggf. Kernel-Parameter nvidia_drm.modeset=1 setzen"
  warn "  GRUB: /etc/default/grub -> GRUB_CMDLINE_LINUX_DEFAULT, danach grub-mkconfig -o /boot/grub/grub.cfg"
  warn "  systemd-boot: Parameter in /boot/loader/entries/*.conf ergänzen"
}

### Login-Manager ###

install_login_manager() {
  [[ "$LOGIN_MANAGER" == "none" ]] && { log "Login-Manager übersprungen"; return 0; }

  log "greetd + tuigreet"
  pkg greetd greetd-tuigreet

  # Session-Auswahl aus /usr/share/wayland-sessions (enthält hyprland.desktop
  # nach `caelestia install`), kein fest verdrahtetes --cmd.
  sudo tee /etc/greetd/config.toml >/dev/null <<-'EOF'
	[terminal]
	vt = 1

	[default_session]
	command = "tuigreet --remember --remember-session --asterisks"
	user = "greeter"
	EOF

  sudo systemctl enable greetd.service
}

### Caelestia ###

install_caelestia() {
  local helper
  helper=$(detect_aur_helper)
  [[ -z "$helper" ]] && helper=$(bootstrap_yay)

  log "AUR-Helper: $helper"
  log "caelestia-cli installieren"
  aur_install "$helper" caelestia-cli

  log "caelestia install (interaktiv – Auswahl optionaler Komponenten wie spotify/vscodium/zen im Prompt)"
  caelestia install
}

main() {
  full_upgrade
  install_gpu_driver
  install_login_manager
  install_caelestia
  log "Fertig. Neustart erforderlich: sudo reboot"
}

main "$@"
