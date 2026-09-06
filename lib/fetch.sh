# shellcheck shell=bash
# Fetch upstream theme / artwork sources into BUILD_DIR.

# Pinned refs for reproducibility (update when bumping rice version)
DR460NIZED_TAG="5.0.3"
SWEET_REF="nova"
SWEET_KDE_REF="master"
CANDY_REF="master"
BEAUTYLINE_REF="master"
WALLPAPERS_REF="master"
PANEL_COLORIZER_REF="main"
WINDOW_BUTTONS_REF="master"
WINDOW_TITLE_REF="master"
BLURRED_REF="main"
SWEET_GTK_RELEASE="https://github.com/EliverLara/Sweet/releases/download/v6.0/Sweet-Dark.tar.xz"

fetch_tarball() {
  local name="$1" url="$2"
  local dir="$BUILD_DIR/$name"
  local archive="$BUILD_DIR/${name}.tar.gz"
  if [[ -d "$dir/.fetched" ]]; then
    log "Already fetched: $name"
    return 0
  fi
  log "Downloading $name..."
  rm -rf "$dir"
  mkdir -p "$dir"
  download "$url" "$archive"
  extract_tar "$archive" "$dir"
  mkdir -p "$dir/.fetched"
  rm -f "$archive"
}

fetch_git_shallow() {
  local name="$1" url="$2" ref="${3:-}"
  local dir="$BUILD_DIR/$name"
  if [[ -d "$dir/.git" ]]; then
    log "Already cloned: $name"
    return 0
  fi
  log "Cloning $name..."
  rm -rf "$dir"
  if [[ -n "$ref" ]]; then
    git clone --depth 1 --branch "$ref" "$url" "$dir" 2>/dev/null \
      || git clone --depth 1 "$url" "$dir"
  else
    git clone --depth 1 "$url" "$dir"
  fi
}

fetch_all_themes() {
  mkdir -p "$BUILD_DIR"

  fetch_tarball garuda-dr460nized \
    "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized/-/archive/${DR460NIZED_TAG}/garuda-dr460nized-${DR460NIZED_TAG}.tar.gz"

  # Sweet full theme (nova branch has kde/; GTK from release tarball)
  if have_cmd git; then
    fetch_git_shallow sweet "https://github.com/EliverLara/sweet.git" "$SWEET_REF"
    fetch_git_shallow sweet-kde "https://github.com/EliverLara/Sweet-kde.git" "$SWEET_KDE_REF"
    fetch_git_shallow candy-icons "https://github.com/EliverLara/candy-icons.git" "$CANDY_REF"
    fetch_git_shallow beautyline \
      "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline.git" "$BEAUTYLINE_REF"
    fetch_git_shallow garuda-wallpapers \
      "https://gitlab.com/garuda-linux/themes-and-settings/artwork/garuda-wallpapers.git" "$WALLPAPERS_REF"
    fetch_git_shallow panel-colorizer \
      "https://github.com/luisbocanegra/plasma-panel-colorizer.git" "$PANEL_COLORIZER_REF"
    fetch_git_shallow window-buttons \
      "https://github.com/optionmishra/applet-window-buttons6.git" "$WINDOW_BUTTONS_REF"
    fetch_git_shallow window-title \
      "https://github.com/dhruv8sh/plasma6-window-title-applet.git" "$WINDOW_TITLE_REF"
    fetch_git_shallow blurredwallpaper \
      "https://github.com/bouteillerAlan/blurredwallpaper.git" "$BLURRED_REF"

    # Prebuilt GTK Sweet-Dark
    if [[ ! -d "$BUILD_DIR/sweet-gtk-dark/.fetched" ]]; then
      log "Downloading Sweet-Dark GTK theme..."
      local_archive="$BUILD_DIR/Sweet-Dark.tar.xz"
      download "$SWEET_GTK_RELEASE" "$local_archive"
      rm -rf "$BUILD_DIR/sweet-gtk-dark"
      mkdir -p "$BUILD_DIR/sweet-gtk-dark"
      tar -xf "$local_archive" -C "$BUILD_DIR/sweet-gtk-dark"
      mkdir -p "$BUILD_DIR/sweet-gtk-dark/.fetched"
      rm -f "$local_archive"
    fi
  else
    die "git is required to fetch theme sources"
  fi
}
