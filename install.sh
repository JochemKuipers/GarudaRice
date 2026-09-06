#!/usr/bin/env bash
# GarudaRice — install Garuda Dr460nized KDE rice on Arch / Fedora / Debian
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=lib/detect.sh
source "$ROOT/lib/detect.sh"
# shellcheck source=lib/fetch.sh
source "$ROOT/lib/fetch.sh"
# shellcheck source=lib/packages.sh
source "$ROOT/lib/packages.sh"
# shellcheck source=lib/install_themes.sh
source "$ROOT/lib/install_themes.sh"
# shellcheck source=lib/install_plasmoids.sh
source "$ROOT/lib/install_plasmoids.sh"
# shellcheck source=lib/install_shell.sh
source "$ROOT/lib/install_shell.sh"
# shellcheck source=lib/apply.sh
source "$ROOT/lib/apply.sh"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install Garuda Linux Dr460nized KDE rice (themes, applets, fish/bash, Konsole)
on Arch, Fedora, or Debian-family systems with Plasma 6.

Options:
  --apply         Also apply Global Theme / reset panels, dock, wallpaper
  --shell-only    Only install fish/bash, starship, and Konsole configs
  --user          Install to ~/.local instead of /usr/local (no root for themes)
  --yes           Skip confirmation prompts
  --shell fish|bash
                  Konsole default shell (default: fish)
  --skip-packages Skip package manager installs
  --skip-fetch    Reuse existing build/ downloads
  -h, --help      Show this help

Examples:
  ./install.sh
  ./install.sh --apply --yes
  ./install.sh --user --shell-only
EOF
}

DO_APPLY=0
SHELL_ONLY=0
USER_INSTALL=0
ASSUME_YES=0
SHELL_CHOICE=fish
SKIP_PACKAGES=0
SKIP_FETCH=0
PREFIX=/usr/local

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) DO_APPLY=1 ;;
    --shell-only) SHELL_ONLY=1 ;;
    --user) USER_INSTALL=1; PREFIX="$HOME/.local" ;;
    --yes|-y) ASSUME_YES=1 ;;
    --shell)
      shift
      SHELL_CHOICE="${1:-}"
      [[ "$SHELL_CHOICE" == "fish" || "$SHELL_CHOICE" == "bash" ]] \
        || die "--shell must be fish or bash"
      ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --skip-fetch) SKIP_FETCH=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

BUILD_DIR="$ROOT/build"
BACKUP_DIR="$HOME/.garuda-rice-backup-$(date +%Y%m%d-%H%M%S)"
export ROOT BUILD_DIR BACKUP_DIR PREFIX USER_INSTALL ASSUME_YES SHELL_CHOICE DISTRO_FAMILY

detect_distro
require_plasma6

if [[ "$SHELL_ONLY" == "1" ]]; then
  [[ "$SKIP_PACKAGES" == "1" ]] || install_packages
  install_shell
  log "Shell-only install finished."
  exit 0
fi

[[ "$SKIP_PACKAGES" == "1" ]] || install_packages
[[ "$SKIP_FETCH" == "1" ]] || fetch_all_themes

# Plasmoids before final theme layout overlay so colorizer paths resolve
install_plasmoids
install_themes

# Refresh layout overlays after plasmoids land
install_dr460nized_assets

install_shell

if [[ "$DO_APPLY" == "1" ]]; then
  apply_rice
else
  log "Themes installed. Apply manually in System Settings → Global Theme → Dr460nized,"
  log "or re-run: $0 --apply"
fi

log "Done."
