#!/usr/bin/env bash
# ==============================================================================
# Arch / Hyprland / Caelestia System Diagnostic Scanner
# Save output to system_scan.txt in the same directory as this script.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/system_scan.txt"

exec > >(tee "$OUTPUT_FILE") 2>&1

echo "=============================================================================="
echo " SYSTEM DIAGNOSTIC REPORT - $(date)"
echo "=============================================================================="
echo ""

echo "--- [1. PACMAN LOG: RECENT UPDATES] ---"
if [ -f /var/log/pacman.log ]; then
    grep -E "upgraded|installed|removed" /var/log/pacman.log | tail -n 30
else
    echo "pacman.log nicht gefunden."
fi
echo ""

echo "--- [2. JOURNALCTL ERRORS (LAST BOOT)] ---"
journalctl -b 0 -p err..emerg --no-pager | tail -n 30
echo ""

echo "--- [3. HYPRLAND & CAELESTIA PACKAGES] ---"
pacman -Qs "hypr|caelestia|ags|waybar|sddm"
echo ""

echo "--- [4. FILE TYPES IN ~/.cache (CREATEHANDLE / FILE VS DIR CHECK)] ---"
find ~/.cache -maxdepth 2 -type f -not -path '*/.*' 2>/dev/null | head -n 30
echo ""

echo "--- [5. CAELESTIA & HYPRLAND CONFIG DIRECTORY STRUCTURE] ---"
ls -la ~/.config/hypr 2>/dev/null || echo "Kein ~/.config/hypr Ordner"
echo ""
ls -la ~/.config/caelestia 2>/dev/null || echo "Kein ~/.config/caelestia Ordner"
echo ""

echo "--- [6. WAYLAND SESSIONS] ---"
ls -la /usr/share/wayland-sessions/ 2>/dev/null
echo ""

echo "=============================================================================="
echo " DIAGNOSTIC COMPLETED."
echo " Output saved to: $OUTPUT_FILE"
echo "=============================================================================="
