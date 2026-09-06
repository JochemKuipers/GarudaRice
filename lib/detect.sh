# shellcheck shell=bash
# Detect distro family and Plasma version. Sourced by install.sh.

detect_distro() {
  local id id_like
  # shellcheck source=/dev/null
  . /etc/os-release
  id="${ID:-}"
  id_like="${ID_LIKE:-}"

  case "$id" in
    arch|endeavouros|manjaro|cachyos|garuda|artix)
      DISTRO_FAMILY=arch
      ;;
    fedora|rhel|centos|rocky|almalinux|nobara)
      DISTRO_FAMILY=fedora
      ;;
    debian|ubuntu|linuxmint|pop|elementary|zorin|neon|kali)
      DISTRO_FAMILY=debian
      ;;
    *)
      case " $id_like " in
        *" arch "*|*"archlinux"*) DISTRO_FAMILY=arch ;;
        *" fedora "*|*"rhel"*) DISTRO_FAMILY=fedora ;;
        *" debian "*|*"ubuntu"*) DISTRO_FAMILY=debian ;;
        *)
          die "Unsupported distro (ID=$id ID_LIKE=$id_like). Need Arch, Fedora, or Debian family."
          ;;
      esac
      ;;
  esac
  export DISTRO_FAMILY
  log "Detected distro family: $DISTRO_FAMILY ($PRETTY_NAME)"
}

require_plasma6() {
  local ver major
  if ! command -v plasmashell >/dev/null 2>&1; then
    die "plasmashell not found. Install KDE Plasma 6 first."
  fi

  # plasmashell --version may abort without a display; try offscreen / file probes
  ver="$(
    QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" plasmashell --version 2>/dev/null \
      | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || true
  )"
  if [[ -z "$ver" ]]; then
    # Fallback: look at plasma desktop package metadata / library path
    if [[ -d /usr/lib/qt6/plugins/plasma ]] || [[ -d /usr/lib64/qt6/plugins/plasma ]]; then
      ver="6.0"
      log "Could not query plasmashell version (no display); assuming Plasma 6 from Qt6 plasma plugins"
    elif pacman -Q plasma-desktop 2>/dev/null | grep -qE ' 6\.'; then
      ver="$(pacman -Q plasma-desktop 2>/dev/null | grep -oE '6\.[0-9]+' | head -1)"
    elif command -v rpm >/dev/null 2>&1 && rpm -q plasma-desktop 2>/dev/null | grep -qE 'plasma-desktop-6'; then
      ver="6.0"
    elif command -v dpkg-query >/dev/null 2>&1 && dpkg-query -W -f='${Version}\n' plasma-desktop 2>/dev/null | grep -qE '^6|^[0-9]+:6'; then
      ver="6.0"
    else
      die "Could not verify Plasma 6. Run from a graphical session or set QT_QPA_PLATFORM=offscreen."
    fi
  fi
  major="${ver%%.*}"
  if [[ -z "$major" || "$major" -lt 6 ]]; then
    die "Plasma 6 required (found: ${ver:-unknown})."
  fi
  log "Plasma version: $ver"
}
