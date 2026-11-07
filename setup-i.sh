#!/usr/bin/env bash
# ==============================================================================
# Caelestia & Hyprland Rebuild/Reset Script
# ==============================================================================

set -e

echo "==> 1. Sichere bestehende Konfigurationen..."
BACKUP_DIR="$HOME/.config/caelestia_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -d "$HOME/.config/caelestia" ]; then
    cp -r "$HOME/.config/caelestia" "$BACKUP_DIR/"
    echo "    - Caelestia-Config nach $BACKUP_DIR gesichert."
fi

if [ -d "$HOME/.config/hypr" ]; then
    cp -r "$HOME/.config/hypr" "$BACKUP_DIR/"
    echo "    - Hyprland-Config nach $BACKUP_DIR gesichert."
fi

echo "==> 2. Beende laufende Caelestia/AGS Prozesse..."
killall caelestia ags 2>/dev/null || true

echo "==> 3. Bereinige defekte Cache- und Laufzeit-Dateien..."
rm -rf "$HOME/.cache/caelestia"
rm -rf "$HOME/.cache/ags"
rm -rf "$HOME/.cache/hypr"
rm -rf "$HOME/.config/caelestia"

echo "==> 4. Erzwinge Neu-Kompilierung von Caelestia aus dem AUR..."
# Entferne den Yay-Build-Cache für einen sauberen Neuaufbau
rm -rf "$HOME/.cache/yay/caelestia" "$HOME/.cache/yay/caelestia-git"

if command -v yay &> /dev/null; then
    yay -Sba --noconfirm caelestia-git || yay -Sba --noconfirm caelestia
else
    echo "FEHLER: yay wurde nicht gefunden. Bitte installiere yay oder nutze deinen AUR-Helper."
    exit 1
fi

echo "==> 5. Initialisiere Caelestia Standard-Dateien..."
if command -v caelestia &> /dev/null; then
    caelestia setup || true
fi

echo "==> 6. Prüfe Hyprland Autostart-Eintrag..."
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    if ! grep -q "exec-once = caelestia run" "$HYPR_CONF"; then
        echo "" >> "$HYPR_CONF"
        echo "# Autostart Caelestia Shell" >> "$HYPR_CONF"
        echo "exec-once = caelestia run" >> "$HYPR_CONF"
        echo "    - 'exec-once = caelestia run' zu hyprland.conf hinzugefügt."
    fi
fi

echo "=============================================================================="
echo " Fertig! Caelestia wurde komplett zurückgesetzt und neu kompiliert."
echo " Starte Hyprland jetzt manuell mit dem Befehl: Hyprland"
echo "=============================================================================="
