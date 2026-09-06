#!/usr/bin/env bash
# GarudaRice — Dr460nized KDE rice for Arch / Fedora / Debian (Plasma 6)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- knobs ---
DR460NIZED_TAG="5.0.3"
SWEET_REF="nova"
SWEET_GTK_RELEASE="https://github.com/EliverLara/Sweet/releases/download/v6.0/Sweet-Dark.tar.xz"

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]
  --apply         Apply Global Theme (resets panels/dock/wallpaper)
  --update        Refresh upstream themes/plasmoids (keeps your layout)
  --shell-only    Only fish/bash + starship + Konsole
  --user          Install under ~/.local
  --yes           Skip confirms
  --shell fish|bash
  -h, --help

Update tip: ./install.sh --update
  Re-downloads/pulls sources and overwrites theme files.
  Does NOT reset panels — add --apply only if Garuda changed the layout.
EOF
}

DO_APPLY=0 DO_UPDATE=0 SHELL_ONLY=0 USER_INSTALL=0 ASSUME_YES=0
SHELL_CHOICE=fish PREFIX=/usr/local

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) DO_APPLY=1 ;;
    --update) DO_UPDATE=1 ;;
    --shell-only) SHELL_ONLY=1 ;;
    --user) USER_INSTALL=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --shell) shift; SHELL_CHOICE="${1:-}"
      [[ "$SHELL_CHOICE" == fish || "$SHELL_CHOICE" == bash ]] || die "--shell must be fish or bash" ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

# Never run the whole script as root — backups/configs would land in /root.
if [[ "$(id -u)" -eq 0 ]]; then
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
    die "Do not use sudo/root. Run as $SUDO_USER without sudo:
  ./install.sh …
(sudo is prompted only for packages and /usr/local writes)"
  fi
  die "Do not run as root. Run as your normal desktop user; sudo is prompted when needed."
fi

REAL_USER="$(id -un)"
REAL_HOME="${HOME:-/home/$REAL_USER}"
[[ -d "$REAL_HOME" ]] || die "Cannot resolve home for $REAL_USER"

[[ "$USER_INSTALL" == 1 ]] && PREFIX="$REAL_HOME/.local"
BUILD_DIR="$ROOT/build"
BACKUP_DIR="$REAL_HOME/.garuda-rice-backup-$(date +%Y%m%d-%H%M%S)"

rice_share() {
  if [[ "$USER_INSTALL" == 1 ]]; then echo "$REAL_HOME/.local/share"
  else echo "$PREFIX/share"; fi
}

confirm() {
  [[ "$ASSUME_YES" == 1 ]] && return 0
  printf '%s [y/N] ' "$1"; read -r a; [[ "$a" =~ ^[Yy]$ ]]
}

# Escalate only for this command — never keep a root shell.
as_root() {
  have sudo || die "Need sudo for privileged installs (packages / $PREFIX)"
  sudo -H "$@"
}

dest_mkdir() { mkdir -p "$1" 2>/dev/null || as_root mkdir -p "$1"; }

dest_install() {
  local src="$1" dest="$2" mode="${3:-0644}"
  dest_mkdir "$(dirname "$dest")"
  if [[ -w "$(dirname "$dest")" ]]; then install -m "$mode" "$src" "$dest"
  else as_root install -m "$mode" "$src" "$dest"; fi
}

dest_cp() {
  # Copy tree into share prefix. Never ship .git; escalate if dest has root leftovers.
  local src="$1" dest="$2" tmp
  dest_mkdir "$dest"

  _copy_tree() {
    # $1 = 0 user, 1 root
    if [[ "$1" == 1 ]]; then
      as_root rm -rf "$dest/.git" "$dest/.fetched"
    else
      rm -rf "$dest/.git" "$dest/.fetched" 2>/dev/null || true
    fi
    if have rsync; then
      if [[ "$1" == 1 ]]; then
        as_root rsync -a --exclude='.git' --exclude='.fetched' "$src"/ "$dest"/
      else
        rsync -a --exclude='.git' --exclude='.fetched' "$src"/ "$dest"/
      fi
    else
      tmp="$(mktemp -d)"
      tar -C "$src" --exclude='.git' --exclude='.fetched' -cf - . | tar -C "$tmp" -xf -
      if [[ "$1" == 1 ]]; then
        as_root cp -a "$tmp"/. "$dest"/
      else
        cp -a "$tmp"/. "$dest"/
      fi
      rm -rf "$tmp"
    fi
  }

  if [[ -w "$dest" ]] && _copy_tree 0 2>/dev/null; then
    unset -f _copy_tree
    return 0
  fi
  _copy_tree 1
  unset -f _copy_tree
}

dest_rm() {
  [[ -e "$1" || -L "$1" ]] || return 0
  # Parent writable ≠ contents removable (root-owned cmake build trees)
  if rm -rf "$1" 2>/dev/null; then return 0; fi
  as_root rm -rf "$1"
}

backup() {
  local src="$1"
  local dest="$BACKUP_DIR/${src#"$REAL_HOME"/}"
  [[ -e "$src" || -L "$src" ]] || return 0
  mkdir -p "$(dirname "$dest")"; cp -a "$src" "$dest"
}

download() {
  mkdir -p "$(dirname "$2")"
  if have curl; then curl -fsSL -o "$2" "$1"
  elif have wget; then wget -q -O "$2" "$1"
  else die "Need curl or wget"; fi
}

# --- detect ---
detect_distro() {
  # shellcheck source=/dev/null
  . /etc/os-release
  case "${ID:-}" in
    arch|endeavouros|manjaro|cachyos|garuda|artix) DISTRO_FAMILY=arch ;;
    fedora|rhel|centos|rocky|almalinux|nobara) DISTRO_FAMILY=fedora ;;
    debian|ubuntu|linuxmint|pop|elementary|zorin|neon|kali|pika|pikaos) DISTRO_FAMILY=debian ;;
    *)
      case " ${ID_LIKE:-} " in
        *" arch "*|*"archlinux"*) DISTRO_FAMILY=arch ;;
        *" fedora "*|*"rhel"*) DISTRO_FAMILY=fedora ;;
        *" debian "*|*"ubuntu"*) DISTRO_FAMILY=debian ;;
        *) die "Unsupported distro ID=${ID:-} ID_LIKE=${ID_LIKE:-}" ;;
      esac ;;
  esac
  log "Distro: $DISTRO_FAMILY ($PRETTY_NAME)"
}

require_plasma6() {
  have plasmashell || die "plasmashell not found — install Plasma 6 first"

  # Never run plasmashell --version here: it can hang forever in VMs / no-display.
  if [[ -d /usr/lib/qt6/plugins/plasma || -d /usr/lib64/qt6/plugins/plasma \
     || -d /usr/lib/x86_64-linux-gnu/qt6/plugins/plasma ]]; then
    log "Plasma 6 OK"
    return
  fi
  # Debian multiarch / other layouts
  if compgen -G '/usr/lib/*/qt6/plugins/plasma' >/dev/null 2>&1; then
    log "Plasma 6 OK"
    return
  fi
  if [[ -e /usr/share/plasma/shells/org.kde.plasma.desktop ]]; then
    log "Plasma 6 OK (desktop shell present)"
    return
  fi
  die "Plasma 6 not detected. Install a Plasma 6 session and retry."
}

# --- early tooling (before fetch / fonts) ---
ensure_tooling() {
  log "Checking tooling..."
  local need=()
  have git    || need+=(git)
  have curl || have wget || need+=(curl)
  have unzip  || need+=(unzip)
  have zip    || need+=(zip)
  have tar    || need+=(tar)
  # Debian often needs xz-utils for .tar.xz
  if [[ "$DISTRO_FAMILY" == debian ]] && ! have xz && ! have xzcat; then
    need+=(xz-utils)
  fi

  if [[ ${#need[@]} -eq 0 ]]; then
    log "Tooling OK"
    return
  fi

  log "Installing missing tools: ${need[*]}"
  case "$DISTRO_FAMILY" in
    arch)
      # tar is in coreutils/filesystem usually; still ask pacman
      pkg "${need[@]}" || die "Failed to install: ${need[*]}"
      ;;
    fedora)
      pkg "${need[@]}" || die "Failed to install: ${need[*]}"
      ;;
    debian)
      # map bare names if needed
      local deb=()
      local n
      for n in "${need[@]}"; do
        case "$n" in
          tar) deb+=(tar) ;;
          *) deb+=("$n") ;;
        esac
      done
      pkg "${deb[@]}" || die "Failed to install: ${deb[*]}"
      ;;
  esac

  have git || die "git still missing after install"
  have curl || have wget || die "curl/wget still missing after install"
  have unzip || die "unzip still missing after install"
  log "Tooling OK"
}

# --- packages ---
APT_UPDATED=0
PKG_OK=()
PKG_FAILED=()

pkg() {
  case "$DISTRO_FAMILY" in
    arch) as_root pacman -S --needed --noconfirm "$@" ;;
    fedora) as_root dnf install -y "$@" ;;
    debian)
      if [[ "$APT_UPDATED" != 1 ]]; then
        as_root apt-get update -qq
        APT_UPDATED=1
      fi
      as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
      ;;
  esac
}

# Is this package/capability already on the system? (no package manager call)
already() {
  case "$1" in
    fish) have fish ;;
    starship) have starship ;;
    bat) have bat ;;
    eza|exa) have eza || have exa ;;
    fzf) have fzf ;;
    fastfetch) have fastfetch ;;
    git) have git ;;
    curl) have curl ;;
    wget) have wget ;;
    unzip) have unzip ;;
    zip) have zip ;;
    tar) have tar ;;
    xz-utils) have xz || have xzcat ;;
    konsole) have konsole ;;
    plasma-workspace) have plasmashell ;;
    kvantum|qt6-style-kvantum|qt6-style-kvantum-themes|libqt6svg6)
      have kvantummanager || have kvantum \
        || [[ -e /usr/lib/qt6/plugins/styles/libkvantum.so ]] \
        || [[ -e /usr/lib64/qt6/plugins/styles/libkvantum.so ]] \
        || compgen -G '/usr/lib/*/qt6/plugins/styles/libkvantum.so' >/dev/null 2>&1 ;;
    kdeplasma-addons|plasma-widgets-addons|plasma6-addons)
      [[ -d /usr/share/plasma/plasmoids/org.kde.plasma.userswitcher ]] ;;
    fonts-firacode|ttf-fira-code|otf-fira-code|fira-code-fonts|fonts-fira-code)
      fc-list 2>/dev/null | grep -qiE 'Fira Code|FiraCode' ;;
    plasma-applet-window-buttons|plasma6-applets-window-buttons)
      [[ -d /usr/share/plasma/plasmoids/org.kde.windowbuttons ]] ;;
    cmake) have cmake ;;
    make) have make ;;
    g++|gcc|gcc-c++) have g++ || have c++ ;;
    python|python3) have python3 ;;
    gettext) have msgfmt ;;
    extra-cmake-modules)
      [[ -d /usr/share/ECM || -d /usr/share/cmake/ECM || -d /usr/share/cmake-*/Modules/ECM ]] ;;
    qt6-base-dev|qt6-qtbase-devel)
      [[ -d /usr/include/qt6/QtCore || -d /usr/include/x86_64-linux-gnu/qt6/QtCore ]] ;;
    qt6-declarative-dev|qt6-qtdeclarative-devel)
      [[ -d /usr/include/qt6/QtQml || -d /usr/include/x86_64-linux-gnu/qt6/QtQml ]] ;;
    libplasma-dev)
      [[ -e /usr/include/Plasma/Plasma || -e /usr/include/plasma6/Plasma/Plasma ]] ;;
    *)
      case "$DISTRO_FAMILY" in
        arch) pacman -Q "$1" &>/dev/null ;;
        fedora) rpm -q "$1" &>/dev/null ;;
        debian) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed' ;;
        *) return 1 ;;
      esac
      ;;
  esac
}

# Only invoke the package manager for what is actually missing.
pkg_each() {
  local p missing=()
  for p in "$@"; do
    if already "$p"; then
      log "  = $p (already present)"
      PKG_OK+=("$p")
    else
      missing+=("$p")
    fi
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  log "Installing missing: ${missing[*]}"
  for p in "${missing[@]}"; do
    if pkg "$p" 2>/dev/null; then
      log "  + $p"
      PKG_OK+=("$p")
    else
      warn "  skip $p (not available)"
      PKG_FAILED+=("$p")
    fi
  done
}

pkg_any() {
  local p
  for p in "$@"; do
    if already "$p"; then
      log "  = $p (already present)"
      PKG_OK+=("$p")
      return 0
    fi
  done
  log "Installing one of: $*"
  for p in "$@"; do
    if pkg "$p" 2>/dev/null; then
      log "  + $p"
      PKG_OK+=("$p")
      return 0
    fi
  done
  warn "  none available of: $*"
  PKG_FAILED+=("any_of[$*]")
  return 1
}

print_pkg_report() {
  echo
  if [[ ${#PKG_FAILED[@]} -eq 0 ]]; then
    log "Package report: nothing missing (or all installs OK)"
    return
  fi
  warn "Package report — failed / unavailable (${#PKG_FAILED[@]}):"
  local p
  for p in "${PKG_FAILED[@]}"; do
    warn "  - $p"
  done
  if [[ ${#PKG_OK[@]} -gt 0 ]]; then
    log "Present/installed (${#PKG_OK[@]}): ${PKG_OK[*]}"
  fi
  warn "Install continues. Install the failed ones manually if you need them."
}

install_starship() {
  have starship && return 0
  log "Installing starship..."
  curl -fsSL https://starship.rs/install.sh | as_root sh -s -- -y
}

install_packages() {
  PKG_OK=()
  PKG_FAILED=()
  log "Packages ($DISTRO_FAMILY) — checking what's already installed..."
  case "$DISTRO_FAMILY" in
    arch)
      pkg_each fish starship bat fzf fastfetch \
        git curl wget unzip zip plasma-workspace konsole kvantum
      pkg_any ttf-fira-code otf-fira-code
      pkg_any kdeplasma-addons
      pkg_any eza
      ;;
    fedora)
      pkg_each fish starship bat fzf fastfetch \
        git curl wget unzip zip plasma-workspace konsole
      pkg_any fira-code-fonts
      pkg_any kvantum
      pkg_any plasma-widgets-addons kdeplasma-addons plasma6-addons
      pkg_any eza
      ;;
    debian)
      if already fish; then
        log "  = fish (already present)"
        PKG_OK+=("fish")
      else
        pkg fish || die "apt could not install fish (enable universe/sid repos if needed)"
        PKG_OK+=("fish")
      fi
      pkg_each bat fzf fastfetch \
        git curl wget unzip zip xz-utils \
        plasma-workspace konsole
      # https://packages.debian.org/sid/fonts/fonts-firacode
      pkg_any fonts-firacode
      pkg_any eza exa
      # Qt6 Kvantum engine (theme files come from garuda-dr460nized)
      if ! pkg_any qt6-style-kvantum; then
        pkg_any qt5-style-kvantum kvantum || warn "Kvantum Qt style missing — install qt6-style-kvantum"
      fi
      pkg_any plasma-widgets-addons kdeplasma-addons
      # Silences “AdwaitaLegacy not found” when Adwaita is pulled in as a fallback
      pkg_any adwaita-icon-theme-legacy adwaita-icon-theme || true
      have starship || install_starship
      have starship && PKG_OK+=("starship") || PKG_FAILED+=("starship")
      ;;
  esac
  have fish || die "fish is required but not installed"
  have starship || install_starship
  have starship || PKG_FAILED+=("starship")
  if ! already kvantum; then
    warn "Kvantum style plugin not detected — Qt apps will stay Breeze until qt6-style-kvantum/kvantum is installed"
  fi
}

# --- fetch ---
clone() {
  local name="$1" url="$2" ref="${3:-}"
  local dir="$BUILD_DIR/$name"
  if [[ -d "$dir/.git" ]]; then
    if [[ "$DO_UPDATE" == 1 ]]; then
      log "Update $name..."
      if [[ -n "$ref" ]]; then
        git -C "$dir" fetch --depth 1 origin "$ref"
        git -C "$dir" checkout -B "$ref" FETCH_HEAD 2>/dev/null \
          || git -C "$dir" reset --hard FETCH_HEAD
      else
        git -C "$dir" pull --ff-only 2>/dev/null \
          || { git -C "$dir" fetch --depth 1 origin; git -C "$dir" reset --hard FETCH_HEAD; }
      fi
      return
    fi
    log "Have $name"
    return
  fi
  log "Clone $name..."
  dest_rm "$dir"
  if [[ -n "$ref" ]]; then
    git clone --depth 1 --branch "$ref" "$url" "$dir" 2>/dev/null || git clone --depth 1 "$url" "$dir"
  else
    git clone --depth 1 "$url" "$dir"
  fi
}

resolve_dr460nized_tag() {
  [[ "$DO_UPDATE" == 1 ]] || return 0
  local latest
  latest="$(
    curl -fsSL \
      'https://gitlab.com/api/v4/projects/garuda-linux%2Fthemes-and-settings%2Fsettings%2Fgaruda-dr460nized/repository/tags?per_page=1' \
      2>/dev/null | grep -oE '"name":"[^"]+"' | head -1 | cut -d'"' -f4 || true
  )"
  if [[ -n "$latest" ]]; then
    log "Latest garuda-dr460nized tag: $latest (was $DR460NIZED_TAG)"
    DR460NIZED_TAG="$latest"
  fi
}

fetch_all() {
  have git || die "git required"
  mkdir -p "$BUILD_DIR"
  resolve_dr460nized_tag

  local tarball="$BUILD_DIR/garuda-dr460nized.tar.gz" src="$BUILD_DIR/garuda-dr460nized"
  if [[ "$DO_UPDATE" == 1 || ! -d "$src/.fetched" ]]; then
    log "Download garuda-dr460nized $DR460NIZED_TAG..."
    dest_rm "$src"; mkdir -p "$src"
    download "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized/-/archive/${DR460NIZED_TAG}/garuda-dr460nized-${DR460NIZED_TAG}.tar.gz" "$tarball"
    tar -xf "$tarball" -C "$src" --strip-components=1 2>/dev/null || tar -xf "$tarball" -C "$src"
    mkdir -p "$src/.fetched"; rm -f "$tarball"
  fi

  clone sweet "https://github.com/EliverLara/sweet.git" "$SWEET_REF"
  clone candy-icons "https://github.com/EliverLara/candy-icons.git"
  clone beautyline "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline.git"
  clone panel-colorizer "https://github.com/luisbocanegra/plasma-panel-colorizer.git"
  # Pure-QML window buttons (no appletdecoration / cmake) — works on Debian/PikaOS
  clone panel-window-controls "https://github.com/EmanCastillo/panelwindowcontrols.git"
  clone window-title "https://github.com/dhruv8sh/plasma6-window-title-applet.git"
  clone blurredwallpaper "https://github.com/bouteillerAlan/blurredwallpaper.git"

  if [[ "$DO_UPDATE" == 1 || ! -d "$BUILD_DIR/sweet-gtk-dark/.fetched" ]]; then
    log "Download Sweet-Dark GTK..."
    download "$SWEET_GTK_RELEASE" "$BUILD_DIR/Sweet-Dark.tar.xz"
    dest_rm "$BUILD_DIR/sweet-gtk-dark"; mkdir -p "$BUILD_DIR/sweet-gtk-dark"
    tar -xf "$BUILD_DIR/Sweet-Dark.tar.xz" -C "$BUILD_DIR/sweet-gtk-dark"
    mkdir -p "$BUILD_DIR/sweet-gtk-dark/.fetched"
    rm -f "$BUILD_DIR/Sweet-Dark.tar.xz"
  fi
}

# --- plasmoids ---
ensure_build_deps() {
  log "Checking build deps (plasmoids)..."
  local need=()
  case "$DISTRO_FAMILY" in
    arch)
      have cmake   || need+=(cmake)
      have make    || need+=(make)
      have g++     || need+=(gcc)
      have python3 || need+=(python)
      ;;
    fedora)
      have cmake   || need+=(cmake)
      have make    || need+=(make)
      have g++     || need+=(gcc-c++)
      have python3 || need+=(python3)
      ;;
    debian)
      have cmake   || need+=(cmake)
      have make    || need+=(make)
      have g++     || need+=(g++)
      have python3 || need+=(python3)
      ;;
  esac

  if [[ ${#need[@]} -eq 0 ]]; then
    log "Build deps OK (already present)"
    return
  fi

  log "Installing missing build deps: ${need[*]}"
  pkg "${need[@]}" || die "Failed to install build deps: ${need[*]}"
  have cmake   || die "cmake still missing"
  have make    || die "make still missing"
  have python3 || die "python3 still missing"
  log "Build deps OK"
}

install_plasmoid_repo() {
  local src="$1" id="$2"
  local SHARE dest
  SHARE="$(rice_share)"
  dest="$SHARE/plasma/plasmoids/$id"

  # Pure QML / package tree — copy into our prefix (never use upstream install.sh as root → /root/.local)
  if [[ -f "$src/metadata.json" || -f "$src/metadata.desktop" ]]; then
    dest_cp "$src" "$dest"
    log "  installed $id → $dest"
    return 0
  fi
  if [[ -d "$src/package" ]] && [[ -f "$src/package/metadata.json" || -f "$src/package/metadata.desktop" ]]; then
    dest_cp "$src/package" "$dest"
    log "  installed $id → $dest"
    return 0
  fi

  warn "No plasmoid package in $src"
  return 1
}

# Dead import on Plasma ≥6.6 where private.appmenu is no longer a public QML module
patch_window_title() {
  local f candidates=(
    "$(rice_share)/plasma/plasmoids/org.kde.windowtitle/contents/ui/main.qml"
    "$REAL_HOME/.local/share/plasma/plasmoids/org.kde.windowtitle/contents/ui/main.qml"
    /usr/local/share/plasma/plasmoids/org.kde.windowtitle/contents/ui/main.qml
    /usr/share/plasma/plasmoids/org.kde.windowtitle/contents/ui/main.qml
  )
  for f in "${candidates[@]}"; do
    [[ -f "$f" ]] || continue
    if grep -q 'org.kde.plasma.private.appmenu' "$f"; then
      if [[ -w "$f" ]]; then
        sed -i '/org\.kde\.plasma\.private\.appmenu/d' "$f"
      else
        as_root sed -i '/org\.kde\.plasma\.private\.appmenu/d' "$f"
      fi
      log "  patched window-title (removed unused private.appmenu import)"
    fi
  done
}

install_plasmoids() {
  local SHARE; SHARE="$(rice_share)"
  ensure_build_deps
  log "Plasmoids..."
  install_plasmoid_repo "$BUILD_DIR/panel-colorizer" "luisbocanegra.panel.colorizer" || die "panel-colorizer failed"
  install_plasmoid_repo "$BUILD_DIR/window-title" "org.kde.windowtitle" || warn "window-title failed"
  patch_window_title
  # Pure QML — no org.kde.appletdecoration / cmake (works on Debian & PikaOS)
  install_plasmoid_repo "$BUILD_DIR/panel-window-controls" "org.emancastillo.panelwindowcontrols" \
    || warn "panel window controls failed"
  # Optional Arch packaged decoration-themed buttons (not required)
  if [[ "$DISTRO_FAMILY" == arch ]]; then
    pkg_any plasma-applet-window-buttons || true
  fi

  local src="$BUILD_DIR/blurredwallpaper"
  if [[ -d "$src/a2n.blur" ]]; then dest_cp "$src/a2n.blur" "$SHARE/plasma/wallpapers/a2n.blur"
  elif [[ -f "$src/metadata.json" ]]; then dest_cp "$src" "$SHARE/plasma/wallpapers/a2n.blur"
  else
    local meta dir
    meta="$(find "$src" -name metadata.json | head -1 || true)"
    if [[ -n "$meta" ]]; then
      dir="$(dirname "$meta")"
      dest_cp "$dir" "$SHARE/plasma/wallpapers/a2n.blur"
    else warn "blurredwallpaper failed"; fi
  fi

  local preset_dest=
  for base in \
    "$SHARE/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "$REAL_HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "/usr/local/share/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer"
  do
    [[ -d "$base/contents/ui/presets" ]] && { preset_dest="$base/contents/ui/presets"; break; }
  done
  if [[ -n "$preset_dest" && -d "$ROOT/overlays/colorizer-presets" ]]; then
    if [[ -w "$preset_dest" ]]; then cp -a "$ROOT/overlays/colorizer-presets/." "$preset_dest"/
    else as_root cp -a "$ROOT/overlays/colorizer-presets/." "$preset_dest"/; fi
  fi
}

# --- themes ---
install_themes() {
  local SHARE src kde colorizer_root tmp meta laf_defaults
  SHARE="$(rice_share)"
  src="$BUILD_DIR/garuda-dr460nized"
  [[ -d "$src/usr/share" ]] || die "garuda-dr460nized missing"

  log "Dr460nized assets..."
  dest_cp "$src/usr/share/plasma/desktoptheme/Dr460nized" "$SHARE/plasma/desktoptheme/Dr460nized"
  dest_cp "$src/usr/share/plasma/look-and-feel/Dr460nized" "$SHARE/plasma/look-and-feel/Dr460nized"
  dest_cp "$src/usr/share/plasma/layout-templates/org.garuda.desktop.defaultPanel" \
    "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultPanel"
  dest_cp "$src/usr/share/plasma/layout-templates/org.garuda.desktop.defaultDock" \
    "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultDock"
  # Garuda tags templates for plasma-garuda; stock Plasma ignores those.
  for layout in defaultPanel defaultDock; do
    meta="$SHARE/plasma/layout-templates/org.garuda.desktop.${layout}/metadata.json"
    [[ -f "$meta" ]] || continue
    if [[ -w "$meta" ]]; then
      sed -i 's/"plasma-garuda"/"org.kde.plasma.desktop"/g' "$meta"
    else
      as_root sed -i 's/"plasma-garuda"/"org.kde.plasma.desktop"/g' "$meta"
    fi
  done
  dest_cp "$src/usr/share/Kvantum/Dr460nized" "$SHARE/Kvantum/Dr460nized"
  # Kvantum only scans ~/.config/Kvantum and /usr/share/Kvantum — not /usr/local or ~/.local/share
  dest_mkdir "$REAL_HOME/.config/Kvantum/Dr460nized"
  cp -a "$src/usr/share/Kvantum/Dr460nized/." "$REAL_HOME/.config/Kvantum/Dr460nized/"
  dest_cp "$src/usr/share/wallpapers/Maldrakor" "$SHARE/wallpapers/Maldrakor"

  # Greeter jpg from Maldrakor plasma wallpaper (skip 63MiB pack)
  dest_mkdir "$SHARE/wallpapers/garuda-wallpapers"
  local img="$SHARE/wallpapers/Maldrakor/contents/images/3840x1920.jpg"
  [[ -f "$img" ]] || img="$(find "$SHARE/wallpapers/Maldrakor" -name '*.jpg' | head -1 || true)"
  if [[ -f "$img" ]]; then
    if [[ -w "$SHARE/wallpapers/garuda-wallpapers" ]]; then cp -f "$img" "$SHARE/wallpapers/garuda-wallpapers/Maldrakor.jpg"
    else as_root cp -f "$img" "$SHARE/wallpapers/garuda-wallpapers/Maldrakor.jpg"; fi
  fi

  if [[ -f "$src/usr/share/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized" ]]; then
    dest_mkdir "$SHARE/aurorae/themes/Sweet-Dark"
    dest_install "$src/usr/share/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized" \
      "$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized"
  elif [[ -f "$ROOT/overlays/Sweet-Darkrc-dr460nized" ]]; then
    dest_mkdir "$SHARE/aurorae/themes/Sweet-Dark"
    dest_install "$ROOT/overlays/Sweet-Darkrc-dr460nized" \
      "$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized"
  fi

  colorizer_root="$SHARE/plasma/plasmoids/luisbocanegra.panel.colorizer"
  for c in "$SHARE" /usr/local/share /usr/share; do
    [[ -d "$c/plasma/plasmoids/luisbocanegra.panel.colorizer" ]] && {
      colorizer_root="$c/plasma/plasmoids/luisbocanegra.panel.colorizer"; break; }
  done
  for layout in defaultDock defaultPanel; do
    [[ -f "$ROOT/overlays/${layout}.layout.js" ]] || continue
    tmp="$(mktemp)"
    sed "s|__COLORIZER_ROOT__|${colorizer_root}|g" "$ROOT/overlays/${layout}.layout.js" >"$tmp"
    dest_install "$tmp" \
      "$SHARE/plasma/layout-templates/org.garuda.desktop.${layout}/contents/layout.js"
    rm -f "$tmp"
  done

  # Point look-and-feel wallpaper defaults at our install prefix
  laf_defaults="$SHARE/plasma/look-and-feel/Dr460nized/contents/defaults"
  if [[ -f "$laf_defaults" ]]; then
    tmp="$(mktemp)"
    sed -e "s|/usr/share/wallpapers|${SHARE}/wallpapers|g" \
        -e 's/^widgetStyle=.*/widgetStyle=kvantum-dark/' \
        "$laf_defaults" >"$tmp"
    # ensure widgetStyle line exists under [kdeglobals][KDE]
    if ! grep -q '^widgetStyle=' "$tmp"; then
      sed -i '/^\[kdeglobals\]\[KDE\]/a widgetStyle=kvantum-dark' "$tmp"
    fi
    dest_install "$tmp" "$laf_defaults"
    rm -f "$tmp"
  fi

  log "Sweet..."
  kde="$BUILD_DIR/sweet/kde"
  [[ -d "$kde" ]] || die "Sweet nova/kde missing"
  [[ -d "$kde/aurorae/Sweet-Dark" ]] && dest_cp "$kde/aurorae/Sweet-Dark" "$SHARE/aurorae/themes/Sweet-Dark"
  [[ -d "$kde/aurorae/Sweet-Dark-transparent" ]] && dest_cp "$kde/aurorae/Sweet-Dark-transparent" "$SHARE/aurorae/themes/Sweet-Dark-transparent"
  [[ -d "$kde/colorschemes" ]] && { dest_mkdir "$SHARE/color-schemes"; dest_cp "$kde/colorschemes" "$SHARE/color-schemes"; }
  [[ -d "$kde/Kvantum/Sweet" ]] && {
    dest_cp "$kde/Kvantum/Sweet" "$SHARE/Kvantum/Sweet"
    dest_mkdir "$REAL_HOME/.config/Kvantum/Sweet"
    cp -a "$kde/Kvantum/Sweet/." "$REAL_HOME/.config/Kvantum/Sweet/"
  }
  [[ -d "$kde/cursors/Sweet-cursors" ]] && dest_cp "$kde/cursors/Sweet-cursors" "$SHARE/icons/Sweet-cursors"
  [[ -d "$kde/konsole" ]] && { dest_mkdir "$SHARE/konsole"; dest_cp "$kde/konsole" "$SHARE/konsole"; }
  [[ -d "$kde/sddm" ]] && dest_cp "$kde/sddm" "$SHARE/sddm/themes/Sweet"

  local gtk="$BUILD_DIR/sweet-gtk-dark/Sweet-Dark"
  [[ -d "$gtk" ]] || gtk="$(find "$BUILD_DIR/sweet-gtk-dark" -maxdepth 2 -type d -name Sweet-Dark | head -1 || true)"
  [[ -n "$gtk" && -d "$gtk" ]] && dest_cp "$gtk" "$SHARE/themes/Sweet-Dark"

  log "Icons..."
  [[ -d "$BUILD_DIR/candy-icons" ]] && dest_cp "$BUILD_DIR/candy-icons" "$SHARE/icons/candy-icons"
  if [[ -f "$BUILD_DIR/beautyline/index.theme" ]]; then
    dest_cp "$BUILD_DIR/beautyline" "$SHARE/icons/BeautyLine"
  else
    local idx; idx="$(find "$BUILD_DIR/beautyline" -name index.theme | head -1 || true)"
    [[ -n "$idx" ]] && dest_cp "$(dirname "$idx")" "$SHARE/icons/BeautyLine"
  fi

  dest_mkdir "$SHARE/icons/garuda"
  [[ -d "$ROOT/overlays/garuda-icons" ]] && dest_cp "$ROOT/overlays/garuda-icons" "$SHARE/icons/garuda"
  if [[ -f "$SHARE/icons/garuda/distributor-logo-garuda.svg" ]]; then
    dest_mkdir "$SHARE/icons/hicolor/scalable/apps"
    if [[ -w "$SHARE/icons/hicolor/scalable/apps" ]]; then
      ln -sfn "$SHARE/icons/garuda/distributor-logo-garuda.svg" \
        "$SHARE/icons/hicolor/scalable/apps/distributor-logo-garuda.svg"
    else
      as_root ln -sfn "$SHARE/icons/garuda/distributor-logo-garuda.svg" \
        "$SHARE/icons/hicolor/scalable/apps/distributor-logo-garuda.svg"
    fi
  fi

  tmp="$(mktemp)"
  sed "s|__GARUDA_ICON_DIR__|${SHARE}/icons/garuda|g" "$ROOT/configs/fastfetch/dr460nized.jsonc" >"$tmp"
  dest_mkdir "$SHARE/fastfetch/presets"
  dest_install "$tmp" "$SHARE/fastfetch/presets/dr460nized.jsonc"
  rm -f "$tmp"

  patch_aurorae
  have gtk-update-icon-cache && {
    gtk-update-icon-cache -f "$SHARE/icons/BeautyLine" 2>/dev/null || true
    gtk-update-icon-cache -f "$SHARE/icons/candy-icons" 2>/dev/null || true
  }
}

patch_aurorae() {
  local SHARE patch t pdir
  SHARE="$(rice_share)"
  patch="$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized"
  [[ -f "$patch" ]] || patch="$ROOT/overlays/Sweet-Darkrc-dr460nized"
  [[ -f "$patch" ]] || return 0
  for t in "$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc" \
           /usr/share/aurorae/themes/Sweet-Dark/Sweet-Darkrc; do
    pdir="$(dirname "$t")"
    [[ -d "$pdir" ]] || continue
    if [[ -w "$pdir" ]]; then cp -f "$patch" "$t"; else as_root cp -f "$patch" "$t"; fi
    log "Patched Aurorae $t"
  done
}

# --- shell ---
install_shell() {
  local SHARE RICE shell_path tmp
  SHARE="$(rice_share)"; RICE="$SHARE/garuda-rice"
  mkdir -p "$BACKUP_DIR"

  dest_mkdir "$RICE/fish"; dest_mkdir "$RICE/bash"; dest_mkdir "$RICE/distro"
  dest_install "$ROOT/configs/shell/fish/config.fish" "$RICE/fish/config.fish"
  dest_install "$ROOT/configs/shell/bash/bashrc" "$RICE/bash/bashrc"
  for f in arch fedora debian; do
    dest_install "$ROOT/configs/shell/distro/$f.fish" "$RICE/distro/$f.fish"
  done
  tmp="$(mktemp)"; printf '%s\n' "$DISTRO_FAMILY" >"$tmp"
  dest_install "$tmp" "$RICE/distro/current"; rm -f "$tmp"

  backup "$REAL_HOME/.config/starship.toml"
  mkdir -p "$REAL_HOME/.config"
  install -m 0644 "$ROOT/configs/shell/common/starship.toml" "$REAL_HOME/.config/starship.toml"

  backup "$REAL_HOME/.config/fish/config.fish"
  mkdir -p "$REAL_HOME/.config/fish"
  cat >"$REAL_HOME/.config/fish/config.fish" <<EOF
# GarudaRice — customize below; defaults: $RICE/fish/config.fish
source $RICE/fish/config.fish
__garuda_rice_fastfetch
EOF

  cat >"$REAL_HOME/.bashrc_garuda_rice" <<EOF
[[ -f $RICE/bash/bashrc ]] && source $RICE/bash/bashrc
EOF
  backup "$REAL_HOME/.bashrc"
  if [[ -f "$REAL_HOME/.bashrc" ]]; then
    grep -q bashrc_garuda_rice "$REAL_HOME/.bashrc" 2>/dev/null \
      || printf '\n# GarudaRice\n[[ -f ~/.bashrc_garuda_rice ]] && source ~/.bashrc_garuda_rice\n' >>"$REAL_HOME/.bashrc"
  else
    printf '# GarudaRice\n[[ -f ~/.bashrc_garuda_rice ]] && source ~/.bashrc_garuda_rice\n' >"$REAL_HOME/.bashrc"
  fi

  case "$SHELL_CHOICE" in
    bash) shell_path="$(command -v bash || echo /bin/bash)" ;;
    *)    shell_path="$(command -v fish || echo /usr/bin/fish)" ;;
  esac
  backup "$REAL_HOME/.local/share/konsole/Garuda.profile"
  mkdir -p "$REAL_HOME/.local/share/konsole"
  tmp="$(mktemp)"
  sed "s|^Command=.*|Command=${shell_path}|" "$ROOT/configs/konsole/Garuda.profile" >"$tmp"
  install -m 0644 "$tmp" "$REAL_HOME/.local/share/konsole/Garuda.profile"
  rm -f "$tmp"
  dest_mkdir "$SHARE/konsole"
  [[ -f "$ROOT/configs/konsole/Sweet.colorscheme" ]] \
    && dest_install "$ROOT/configs/konsole/Sweet.colorscheme" "$SHARE/konsole/Sweet.colorscheme"
  dest_install "$REAL_HOME/.local/share/konsole/Garuda.profile" "$SHARE/konsole/Garuda.profile" 2>/dev/null || true

  backup "$REAL_HOME/.config/konsolerc"
  install -m 0644 "$ROOT/configs/skel/.config/konsolerc" "$REAL_HOME/.config/konsolerc"
  log "Shell OK (konsole → $SHELL_CHOICE) as $REAL_USER"
}

# --- apply ---
apply_rice() {
  confirm "RESET Plasma panels/dock/wallpaper to Dr460nized?" || die "Cancelled"
  local SHARE skel f shell_path
  SHARE="$(rice_share)"; skel="$ROOT/configs/skel"
  mkdir -p "$BACKUP_DIR"
  log "Backup → $BACKUP_DIR"

  for f in \
    .config/kdeglobals .config/kwinrc .config/kcminputrc .config/konsolerc \
    .config/kscreenlockerrc .config/dolphinrc .config/baloofilerc .config/katerc \
    .config/Kvantum/kvantum.kvconfig \
    .config/gtk-3.0/settings.ini .config/gtk-3.0/gtk.css .config/gtk-3.0/colors.css \
    .config/gtk-4.0/settings.ini .config/gtk-4.0/gtk.css .config/gtk-4.0/colors.css \
    .icons/default/index.theme .local/share/konsole/Garuda.profile
  do
    backup "$REAL_HOME/$f"
    [[ -f "$skel/$f" ]] || continue
    mkdir -p "$(dirname "$REAL_HOME/$f")"
    if [[ "$f" == .config/kscreenlockerrc ]]; then
      sed "s|/usr/share/wallpapers|${SHARE}/wallpapers|g" "$skel/$f" >"$REAL_HOME/$f"
    else
      install -m 0644 "$skel/$f" "$REAL_HOME/$f"
    fi
  done

  case "$SHELL_CHOICE" in
    bash) shell_path="$(command -v bash || echo /bin/bash)" ;;
    *)    shell_path="$(command -v fish || echo /usr/bin/fish)" ;;
  esac
  [[ -f "$REAL_HOME/.local/share/konsole/Garuda.profile" ]] \
    && sed -i "s|^Command=.*|Command=${shell_path}|" "$REAL_HOME/.local/share/konsole/Garuda.profile"

  patch_aurorae

  # Write Kvantum config only — never call kvantummanager (GUI pops on errors)
  apply_kvantum_config() {
    mkdir -p "$REAL_HOME/.config/Kvantum"
    printf '%s\n' '[General]' 'theme=Dr460nized' >"$REAL_HOME/.config/Kvantum/kvantum.kvconfig"
    [[ -f "$REAL_HOME/.config/kdeglobals" ]] || return 0
    if grep -q '^widgetStyle=' "$REAL_HOME/.config/kdeglobals"; then
      sed -i 's/^widgetStyle=.*/widgetStyle=kvantum-dark/' "$REAL_HOME/.config/kdeglobals"
    elif grep -q '^\[KDE\]' "$REAL_HOME/.config/kdeglobals"; then
      sed -i '/^\[KDE\]/a widgetStyle=kvantum-dark' "$REAL_HOME/.config/kdeglobals"
    else
      printf '\n[KDE]\nwidgetStyle=kvantum-dark\nLookAndFeelPackage=Dr460nized\n' \
        >>"$REAL_HOME/.config/kdeglobals"
    fi
  }
  apply_kvantum_config

  log "Applying Dr460nized (resets panels/dock)..."
  if have plasma-apply-lookandfeel; then
    plasma-apply-lookandfeel -a Dr460nized \
      || warn "apply failed — set Global Theme → Dr460nized in System Settings"
  elif have lookandfeeltool; then
    lookandfeeltool -a Dr460nized || warn "lookandfeeltool failed"
  else
    warn "No look-and-feel tool; apply Dr460nized in System Settings"
  fi

  apply_kvantum_config

  log "Done. Log out/in (or: plasmashell --replace &). Backup: $BACKUP_DIR"
}

# --- main ---
detect_distro
ensure_tooling
require_plasma6

if [[ "$SHELL_ONLY" == 1 ]]; then
  install_packages
  install_shell
  print_pkg_report
  log "Shell-only finished."
  exit 0
fi

if [[ "$DO_UPDATE" == 1 ]]; then
  # Refresh assets only — no package churn, no shell rewrite, no layout reset
  fetch_all
  install_plasmoids
  install_themes
  if [[ "$DO_APPLY" == 1 ]]; then apply_rice
  else log "Updated themes/plasmoids. Layout untouched (use --apply to reset panels)."; fi
  print_pkg_report
  log "Done."
  exit 0
fi

install_packages
fetch_all
install_plasmoids
install_themes
install_shell

if [[ "$DO_APPLY" == 1 ]]; then apply_rice
else
  log "Installed. Apply via System Settings → Global Theme → Dr460nized,"
  log "or: $0 --apply"
fi
print_pkg_report
log "Done."
