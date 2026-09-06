#!/usr/bin/env bash
# Remove GarudaRice system/user share files. Leaves ~/.config alone.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"

USER_INSTALL=0
PREFIX=/usr/local
ASSUME_YES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) USER_INSTALL=1; PREFIX="$HOME/.local" ;;
    --yes|-y) ASSUME_YES=1 ;;
    -h|--help)
      echo "Usage: ./uninstall.sh [--user] [--yes]"
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

SHARE="$PREFIX/share"
[[ "$USER_INSTALL" == "1" ]] && SHARE="$HOME/.local/share"

confirm "Remove GarudaRice files under $SHARE?" || die "Cancelled"

paths=(
  "$SHARE/plasma/desktoptheme/Dr460nized"
  "$SHARE/plasma/look-and-feel/Dr460nized"
  "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultPanel"
  "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultDock"
  "$SHARE/Kvantum/Dr460nized"
  "$SHARE/wallpapers/Maldrakor"
  "$SHARE/garuda-rice"
  "$SHARE/fastfetch/presets/dr460nized.jsonc"
  "$SHARE/icons/garuda"
  "$SHARE/konsole/Garuda.profile"
)

for p in "${paths[@]}"; do
  dest_rm "$p"
  log "Removed $p"
done

log "Uninstall finished. User configs (~/.config, shell stubs) were left in place."
log "Remove ~/.bashrc_garuda_rice and the GarudaRice line in ~/.bashrc manually if desired."
