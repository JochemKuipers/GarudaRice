#!/usr/bin/env bash
# Remove GarudaRice share files (keeps ~/.config)
set -euo pipefail

log()  { printf '==> %s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

if [[ "$(id -u)" -eq 0 ]]; then
  die "Do not run as root/sudo. Run as your user; sudo is prompted only to delete system files."
fi

USER_INSTALL=0 PREFIX=/usr/local ASSUME_YES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) USER_INSTALL=1; PREFIX="$HOME/.local" ;;
    --yes|-y) ASSUME_YES=1 ;;
    -h|--help) echo "Usage: ./uninstall.sh [--user] [--yes]"; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

SHARE="$PREFIX/share"
[[ "$USER_INSTALL" == 1 ]] && SHARE="$HOME/.local/share"

if [[ "$ASSUME_YES" != 1 ]]; then
  printf 'Remove GarudaRice under %s? [y/N] ' "$SHARE"
  read -r a; [[ "$a" =~ ^[Yy]$ ]] || die "Cancelled"
fi

rm_path() {
  [[ -e "$1" || -L "$1" ]] || return 0
  if [[ -w "$(dirname "$1")" ]]; then rm -rf "$1"
  elif command -v sudo >/dev/null; then sudo -H rm -rf "$1"
  else die "Need sudo to remove $1"; fi
  log "Removed $1"
}

for p in \
  "$SHARE/plasma/desktoptheme/Dr460nized" \
  "$SHARE/plasma/look-and-feel/Dr460nized" \
  "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultPanel" \
  "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultDock" \
  "$SHARE/Kvantum/Dr460nized" \
  "$SHARE/Kvantum/Sweet" \
  "$HOME/.config/Kvantum/Dr460nized" \
  "$HOME/.config/Kvantum/Sweet" \
  "$SHARE/wallpapers/Maldrakor" \
  "$SHARE/wallpapers/garuda-wallpapers" \
  "$SHARE/garuda-rice" \
  "$SHARE/fastfetch/presets/dr460nized.jsonc" \
  "$SHARE/icons/garuda" \
  "$SHARE/konsole/Garuda.profile"
do
  rm_path "$p"
done

log "Uninstall finished. Remove ~/.bashrc_garuda_rice manually if desired."
