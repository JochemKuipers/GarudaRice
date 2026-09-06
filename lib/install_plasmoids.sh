# shellcheck shell=bash
# Install Plasma 6 applets / wallpaper plugin.

install_qml_plasmoid() {
  local src="$1" id="$2" dest_kind="${3:-plasmoids}"
  local SHARE
  SHARE="$(_rice_share)"
  local dest="$SHARE/plasma/${dest_kind}/$id"
  if [[ -f "$src/metadata.json" || -f "$src/metadata.desktop" ]]; then
    dest_cp_tree "$src" "$dest"
    return 0
  fi
  # some repos wrap package/
  if [[ -d "$src/package" ]]; then
    dest_cp_tree "$src/package" "$dest"
    return 0
  fi
  warn "Could not locate plasmoid package in $src"
  return 1
}

build_window_buttons() {
  local src="$BUILD_DIR/window-buttons"
  [[ -d "$src" ]] || return 1

  # Prefer QML-only / install script if present
  if [[ -f "$src/install.sh" ]]; then
    log "Installing window-buttons via project install.sh..."
    (
      cd "$src"
      if [[ "$USER_INSTALL" == "1" ]]; then
        bash ./install.sh
      else
        run_as_root bash ./install.sh
      fi
    ) && return 0
  fi

  log "Building window-buttons (cmake)..."
  local build="$src/build"
  mkdir -p "$build"
  if ! cmake -S "$src" -B "$build" -DCMAKE_INSTALL_PREFIX="$PREFIX" 2>/dev/null; then
    warn "cmake configure for window-buttons failed; skipping compiled applet"
    return 1
  fi
  cmake --build "$build" -j"$(nproc 2>/dev/null || echo 2)" || return 1
  if [[ "$USER_INSTALL" == "1" ]]; then
    cmake --install "$build"
  else
    run_as_root cmake --install "$build"
  fi
}

install_panel_colorizer() {
  local SHARE
  SHARE="$(_rice_share)"
  local src="$BUILD_DIR/panel-colorizer"
  [[ -d "$src" ]] || die "panel-colorizer not fetched"

  log "Installing Panel Colorizer..."
  if [[ -f "$src/install.sh" ]]; then
    (
      cd "$src"
      if [[ "$USER_INSTALL" == "1" ]]; then
        bash ./install.sh
      else
        run_as_root bash ./install.sh
      fi
    ) || install_qml_plasmoid "$src" "luisbocanegra.panel.colorizer"
  else
    install_qml_plasmoid "$src" "luisbocanegra.panel.colorizer" \
      || install_qml_plasmoid "$src/package" "luisbocanegra.panel.colorizer"
  fi

  # Dr460nized presets
  local preset_dest
  for base in \
    "$SHARE/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "$HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "/usr/local/share/plasma/plasmoids/luisbocanegra.panel.colorizer"
  do
    if [[ -d "$base/contents/ui/presets" ]]; then
      preset_dest="$base/contents/ui/presets"
      break
    fi
  done

  if [[ -n "${preset_dest:-}" && -d "$ROOT/overlays/colorizer-presets" ]]; then
    log "Installing Dr460nized Panel Colorizer presets..."
    if [[ -w "$preset_dest" ]]; then
      cp -a "$ROOT/overlays/colorizer-presets/." "$preset_dest"/
    else
      run_as_root cp -a "$ROOT/overlays/colorizer-presets/." "$preset_dest"/
    fi
    # Rewrite lastPreset paths in layout templates already installed use /usr/share — also install copies under SHARE
  fi
}

install_window_title() {
  local src="$BUILD_DIR/window-title"
  [[ -d "$src" ]] || return 1
  log "Installing window-title applet..."
  if [[ -f "$src/install.sh" ]]; then
    (
      cd "$src"
      if [[ "$USER_INSTALL" == "1" ]]; then
        bash ./install.sh
      else
        run_as_root bash ./install.sh
      fi
    ) && return 0
  fi
  install_qml_plasmoid "$src" "org.kde.windowtitle"
}

install_blurred_wallpaper() {
  local SHARE
  SHARE="$(_rice_share)"
  local src="$BUILD_DIR/blurredwallpaper"
  [[ -d "$src" ]] || return 1
  log "Installing blurredwallpaper plugin..."
  if [[ -d "$src/a2n.blur" ]]; then
    dest_cp_tree "$src/a2n.blur" "$SHARE/plasma/wallpapers/a2n.blur"
  elif [[ -f "$src/metadata.json" ]]; then
    dest_cp_tree "$src" "$SHARE/plasma/wallpapers/a2n.blur"
  else
    # common layout: package named package/ or contents at root with metadata
    find "$src" -name 'metadata.json' | while read -r meta; do
      local dir
      dir="$(dirname "$meta")"
      if grep -q 'a2n.blur\|Blurred' "$meta" 2>/dev/null; then
        dest_cp_tree "$dir" "$SHARE/plasma/wallpapers/a2n.blur"
        break
      fi
    done
  fi
}

install_plasmoids() {
  install_panel_colorizer
  install_window_title || warn "window-title applet install failed"
  build_window_buttons || warn "window-buttons applet install failed (panel buttons may be missing)"
  install_blurred_wallpaper || warn "blurredwallpaper install failed"
}
