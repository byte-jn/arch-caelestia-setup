#!/usr/bin/env bash
# ==============================================================================
# Caelestia & Hyprland Auto-Fix Script
# Behebt Cache-Konflikte, Re-kompiliert AUR-Pakete und stellt Configs wieder her.
# ==============================================================================

set -e

echo "==> 1. Erstelle Backup von ~/.config/hypr..."
BACKUP_DIR="$HOME/.config/hypr_backup_$(date +%Y%m%d_%H%M%S)"
if [ -d "$HOME/.config/hypr" ]; then
    cp -r "$HOME/.config/hypr" "$BACKUP_DIR"
    echo "    -> Gesichert nach: $BACKUP_DIR"
fi

echo "==> 2. Beende laufende Caelestia/AGS-Prozesse..."
killall caelestia ags 2>/dev/null || true

echo "==> 3. Bereinige Cache-Ordner und veraltete Laufzeit-Dateien..."
rm -rf "$HOME/.cache/caelestia"
rm -rf "$HOME/.cache/ags"
rm -rf "$HOME/.cache/hypr"

echo "==> 4. Bereinige AUR-Build-Cache von Yay..."
rm -rf "$HOME/.cache/yay/caelestia"*

echo "==> 5. Erstelle fehlendes ~/.config/caelestia Verzeichnis..."
mkdir -p "$HOME/.config/caelestia"

echo "==> 6. Baue Caelestia AUR-Pakete neu für Hyprland v0.57.1..."
if command -v yay &> /dev/null; then
    yay -Sba --noconfirm caelestia-git caelestia-shell caelestia-cli || yay -Sba --noconfirm caelestia-git
else
    echo "FEHLER: 'yay' wurde nicht gefunden!"
    exit 1
fi

echo "==> 7. Initialisiere Caelestia Standard-Setup..."
if command -v caelestia &> /dev/null; then
    caelestia setup || true
fi

echo "==> 8. Prüfe Autostart in hyprland.conf..."
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    if ! grep -q "exec-once = caelestia run" "$HYPR_CONF"; then
        echo "" >> "$HYPR_CONF"
        echo "# Caelestia Desktop Shell Autostart" >> "$HYPR_CONF"
        echo "exec-once = caelestia run" >> "$HYPR_CONF"
        echo "    -> 'exec-once = caelestia run' wurde hinzugefügt."
    fi
fi

echo "=============================================================================="
echo " SUCCESS: System wurde repariert!"
echo " Starte deine Grafikumgebung jetzt mit dem Befehl: Hyprland"
echo "=============================================================================="
