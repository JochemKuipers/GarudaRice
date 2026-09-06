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
    --user) USER_INSTALL=1; PREFIX="$HOME/.local" ;;
    --yes|-y) ASSUME_YES=1 ;;
    --shell) shift; SHELL_CHOICE="${1:-}"
      [[ "$SHELL_CHOICE" == fish || "$SHELL_CHOICE" == bash ]] || die "--shell must be fish or bash" ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

BUILD_DIR="$ROOT/build"
BACKUP_DIR="$HOME/.garuda-rice-backup-$(date +%Y%m%d-%H%M%S)"

rice_share() {
  if [[ "$USER_INSTALL" == 1 ]]; then echo "$HOME/.local/share"
  else echo "$PREFIX/share"; fi
}

confirm() {
  [[ "$ASSUME_YES" == 1 ]] && return 0
  printf '%s [y/N] ' "$1"; read -r a; [[ "$a" =~ ^[Yy]$ ]]
}

as_root() {
  [[ "$(id -u)" -eq 0 ]] && { "$@"; return; }
  have sudo || die "Need sudo for $PREFIX"
  sudo "$@"
}

dest_mkdir() { mkdir -p "$1" 2>/dev/null || as_root mkdir -p "$1"; }

dest_install() {
  local src="$1" dest="$2" mode="${3:-0644}"
  dest_mkdir "$(dirname "$dest")"
  if [[ -w "$(dirname "$dest")" ]]; then install -m "$mode" "$src" "$dest"
  else as_root install -m "$mode" "$src" "$dest"; fi
}

dest_cp() {
  dest_mkdir "$2"
  if [[ -w "$2" ]]; then cp -a "$1"/. "$2"/
  else as_root cp -a "$1"/. "$2"/; fi
}

dest_rm() {
  [[ -e "$1" || -L "$1" ]] || return 0
  if [[ -w "$(dirname "$1")" ]]; then rm -rf "$1"; else as_root rm -rf "$1"; fi
}

backup() {
  local src="$1"
  local dest="$BACKUP_DIR/${src#"$HOME"/}"
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

# --- packages ---
pkg() {
  case "$DISTRO_FAMILY" in
    arch) as_root pacman -S --needed --noconfirm "$@" ;;
    fedora) as_root dnf install -y "$@" ;;
    debian) as_root apt-get update -qq
            as_root DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
  esac
}

install_nerd_font() {
  fc-list 2>/dev/null | grep -qi 'FiraCode Nerd' && return 0
  local dir
  [[ "$USER_INSTALL" == 1 ]] && dir="$HOME/.local/share/fonts/FiraCodeNerd" || dir="$PREFIX/share/fonts/FiraCodeNerd"
  log "Downloading FiraCode Nerd Font..."
  download "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip" "$BUILD_DIR/FiraCode.zip"
  dest_mkdir "$dir"
  if [[ -w "$dir" ]]; then unzip -o -q "$BUILD_DIR/FiraCode.zip" -d "$dir"
  else as_root unzip -o -q "$BUILD_DIR/FiraCode.zip" -d "$dir"; fi
  fc-cache -f "$dir" 2>/dev/null || true
}

install_starship() {
  have starship && return 0
  log "Installing starship..."
  curl -fsSL https://starship.rs/install.sh | as_root sh -s -- -y
}

install_packages() {
  log "Packages ($DISTRO_FAMILY)..."
  case "$DISTRO_FAMILY" in
    arch)
      pkg kvantum fish starship bat eza fzf fastfetch \
          ttf-fira-sans ttf-firacode-nerd git curl unzip \
          plasma-workspace konsole || warn "some pacman packages failed"
      ;;
    fedora)
      pkg kvantum fish starship bat eza fzf fastfetch \
          mozilla-fira-sans-fonts git curl unzip \
          plasma-workspace konsole || warn "some dnf packages failed"
      install_nerd_font
      ;;
    debian)
      pkg fish bat eza fzf fastfetch fonts-fira-sans \
          git curl unzip plasma-workspace konsole \
          qt6-style-kvantum 2>/dev/null \
        || pkg kvantum 2>/dev/null \
        || warn "Install Kvantum manually if missing"
      install_starship
      install_nerd_font
      ;;
  esac
  have fish || die "fish failed to install"
  have starship || install_starship
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
  rm -rf "$dir"
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
    rm -rf "$src"; mkdir -p "$src"
    download "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized/-/archive/${DR460NIZED_TAG}/garuda-dr460nized-${DR460NIZED_TAG}.tar.gz" "$tarball"
    tar -xf "$tarball" -C "$src" --strip-components=1 2>/dev/null || tar -xf "$tarball" -C "$src"
    mkdir -p "$src/.fetched"; rm -f "$tarball"
  fi

  clone sweet "https://github.com/EliverLara/sweet.git" "$SWEET_REF"
  clone candy-icons "https://github.com/EliverLara/candy-icons.git"
  clone beautyline "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline.git"
  clone panel-colorizer "https://github.com/luisbocanegra/plasma-panel-colorizer.git"
  clone window-buttons "https://github.com/optionmishra/applet-window-buttons6.git"
  clone window-title "https://github.com/dhruv8sh/plasma6-window-title-applet.git"
  clone blurredwallpaper "https://github.com/bouteillerAlan/blurredwallpaper.git"

  if [[ "$DO_UPDATE" == 1 || ! -d "$BUILD_DIR/sweet-gtk-dark/.fetched" ]]; then
    log "Download Sweet-Dark GTK..."
    download "$SWEET_GTK_RELEASE" "$BUILD_DIR/Sweet-Dark.tar.xz"
    rm -rf "$BUILD_DIR/sweet-gtk-dark"; mkdir -p "$BUILD_DIR/sweet-gtk-dark"
    tar -xf "$BUILD_DIR/Sweet-Dark.tar.xz" -C "$BUILD_DIR/sweet-gtk-dark"
    mkdir -p "$BUILD_DIR/sweet-gtk-dark/.fetched"
    rm -f "$BUILD_DIR/Sweet-Dark.tar.xz"
  fi
}

# --- plasmoids ---
install_plasmoid_repo() {
  local src="$1" id="$2"
  local SHARE dest
  SHARE="$(rice_share)"
  dest="$SHARE/plasma/plasmoids/$id"
  if [[ -f "$src/install.sh" ]]; then
    (cd "$src" && if [[ "$USER_INSTALL" == 1 ]]; then bash ./install.sh; else as_root bash ./install.sh; fi) && return 0
  fi
  if [[ -f "$src/metadata.json" || -f "$src/metadata.desktop" ]]; then dest_cp "$src" "$dest"; return 0; fi
  if [[ -d "$src/package" ]]; then dest_cp "$src/package" "$dest"; return 0; fi
  warn "No plasmoid package in $src"; return 1
}

install_plasmoids() {
  local SHARE; SHARE="$(rice_share)"
  log "Plasmoids..."
  install_plasmoid_repo "$BUILD_DIR/panel-colorizer" "luisbocanegra.panel.colorizer" || die "panel-colorizer failed"
  install_plasmoid_repo "$BUILD_DIR/window-title" "org.kde.windowtitle" || warn "window-title failed"
  install_plasmoid_repo "$BUILD_DIR/window-buttons" "org.kde.windowbuttons" || warn "window-buttons failed"

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
    "$HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer" \
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
  local SHARE src kde colorizer_root tmp
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
  dest_cp "$src/usr/share/Kvantum/Dr460nized" "$SHARE/Kvantum/Dr460nized"
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

  log "Sweet..."
  kde="$BUILD_DIR/sweet/kde"
  [[ -d "$kde" ]] || die "Sweet nova/kde missing"
  [[ -d "$kde/aurorae/Sweet-Dark" ]] && dest_cp "$kde/aurorae/Sweet-Dark" "$SHARE/aurorae/themes/Sweet-Dark"
  [[ -d "$kde/aurorae/Sweet-Dark-transparent" ]] && dest_cp "$kde/aurorae/Sweet-Dark-transparent" "$SHARE/aurorae/themes/Sweet-Dark-transparent"
  [[ -d "$kde/colorschemes" ]] && { dest_mkdir "$SHARE/color-schemes"; dest_cp "$kde/colorschemes" "$SHARE/color-schemes"; }
  [[ -d "$kde/Kvantum/Sweet" ]] && dest_cp "$kde/Kvantum/Sweet" "$SHARE/Kvantum/Sweet"
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

  backup "$HOME/.config/starship.toml"
  mkdir -p "$HOME/.config"
  install -m 0644 "$ROOT/configs/shell/common/starship.toml" "$HOME/.config/starship.toml"

  backup "$HOME/.config/fish/config.fish"
  mkdir -p "$HOME/.config/fish"
  cat >"$HOME/.config/fish/config.fish" <<EOF
# GarudaRice — customize below; defaults: $RICE/fish/config.fish
source $RICE/fish/config.fish
__garuda_rice_fastfetch
EOF

  cat >"$HOME/.bashrc_garuda_rice" <<EOF
[[ -f $RICE/bash/bashrc ]] && source $RICE/bash/bashrc
EOF
  backup "$HOME/.bashrc"
  if [[ -f "$HOME/.bashrc" ]]; then
    grep -q bashrc_garuda_rice "$HOME/.bashrc" 2>/dev/null \
      || printf '\n# GarudaRice\n[[ -f ~/.bashrc_garuda_rice ]] && source ~/.bashrc_garuda_rice\n' >>"$HOME/.bashrc"
  else
    printf '# GarudaRice\n[[ -f ~/.bashrc_garuda_rice ]] && source ~/.bashrc_garuda_rice\n' >"$HOME/.bashrc"
  fi

  case "$SHELL_CHOICE" in
    bash) shell_path="$(command -v bash || echo /bin/bash)" ;;
    *)    shell_path="$(command -v fish || echo /usr/bin/fish)" ;;
  esac
  backup "$HOME/.local/share/konsole/Garuda.profile"
  mkdir -p "$HOME/.local/share/konsole"
  tmp="$(mktemp)"
  sed "s|^Command=.*|Command=${shell_path}|" "$ROOT/configs/konsole/Garuda.profile" >"$tmp"
  install -m 0644 "$tmp" "$HOME/.local/share/konsole/Garuda.profile"
  rm -f "$tmp"
  dest_mkdir "$SHARE/konsole"
  [[ -f "$ROOT/configs/konsole/Sweet.colorscheme" ]] \
    && dest_install "$ROOT/configs/konsole/Sweet.colorscheme" "$SHARE/konsole/Sweet.colorscheme"
  dest_install "$HOME/.local/share/konsole/Garuda.profile" "$SHARE/konsole/Garuda.profile" 2>/dev/null || true

  backup "$HOME/.config/konsolerc"
  install -m 0644 "$ROOT/configs/skel/.config/konsolerc" "$HOME/.config/konsolerc"
  log "Shell OK (konsole → $SHELL_CHOICE)"
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
    backup "$HOME/$f"
    [[ -f "$skel/$f" ]] || continue
    mkdir -p "$(dirname "$HOME/$f")"
    if [[ "$f" == .config/kscreenlockerrc ]]; then
      sed "s|/usr/share/wallpapers|${SHARE}/wallpapers|g" "$skel/$f" >"$HOME/$f"
    else
      install -m 0644 "$skel/$f" "$HOME/$f"
    fi
  done

  case "$SHELL_CHOICE" in
    bash) shell_path="$(command -v bash || echo /bin/bash)" ;;
    *)    shell_path="$(command -v fish || echo /usr/bin/fish)" ;;
  esac
  [[ -f "$HOME/.local/share/konsole/Garuda.profile" ]] \
    && sed -i "s|^Command=.*|Command=${shell_path}|" "$HOME/.local/share/konsole/Garuda.profile"

  patch_aurorae
  log "Applying Dr460nized..."
  if have plasma-apply-lookandfeel; then
    plasma-apply-lookandfeel -a Dr460nized \
      || warn "apply failed — set Global Theme → Dr460nized in System Settings"
  elif have lookandfeeltool; then
    lookandfeeltool -a Dr460nized || warn "lookandfeeltool failed"
  else
    warn "No look-and-feel tool; apply Dr460nized in System Settings"
  fi
  log "Done. Log out/in (or: plasmashell --replace &). Backup: $BACKUP_DIR"
}

# --- main ---
detect_distro
require_plasma6

if [[ "$SHELL_ONLY" == 1 ]]; then
  install_packages
  install_shell
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
log "Done."
