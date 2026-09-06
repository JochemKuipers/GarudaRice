# shellcheck shell=bash
# Install theme assets into PREFIX/share (or ~/.local/share).

install_dr460nized_assets() {
  local SHARE
  SHARE="$(_rice_share)"
  local src="$BUILD_DIR/garuda-dr460nized"
  # Tarball may nest once
  if [[ ! -d "$src/usr" ]]; then
    local nested
    nested="$(find "$BUILD_DIR" -maxdepth 2 -type d -name 'garuda-dr460nized*' | head -1)"
    [[ -n "$nested" && -d "$nested/usr" ]] && src="$nested"
  fi
  [[ -d "$src/usr/share" ]] || die "garuda-dr460nized sources missing under $BUILD_DIR"

  log "Installing Dr460nized plasma / look-and-feel / Kvantum / wallpaper..."

  dest_cp_tree "$src/usr/share/plasma/desktoptheme/Dr460nized" "$SHARE/plasma/desktoptheme/Dr460nized"
  dest_cp_tree "$src/usr/share/plasma/look-and-feel/Dr460nized" "$SHARE/plasma/look-and-feel/Dr460nized"
  dest_cp_tree "$src/usr/share/plasma/layout-templates/org.garuda.desktop.defaultPanel" \
    "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultPanel"
  dest_cp_tree "$src/usr/share/plasma/layout-templates/org.garuda.desktop.defaultDock" \
    "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultDock"
  dest_cp_tree "$src/usr/share/Kvantum/Dr460nized" "$SHARE/Kvantum/Dr460nized"
  dest_cp_tree "$src/usr/share/wallpapers/Maldrakor" "$SHARE/wallpapers/Maldrakor"

  # Aurorae patch file (applied later against Sweet-Dark)
  if [[ -f "$src/usr/share/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized" ]]; then
    dest_mkdir "$SHARE/aurorae/themes/Sweet-Dark"
    dest_install "$src/usr/share/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized" \
      "$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized"
  elif [[ -f "$ROOT/overlays/Sweet-Darkrc-dr460nized" ]]; then
    dest_mkdir "$SHARE/aurorae/themes/Sweet-Dark"
    dest_install "$ROOT/overlays/Sweet-Darkrc-dr460nized" \
      "$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized"
  fi

  # Overlay portable dock / panel layouts with correct colorizer paths
  local colorizer_root="$SHARE/plasma/plasmoids/luisbocanegra.panel.colorizer"
  for candidate in \
    "$SHARE/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "/usr/local/share/plasma/plasmoids/luisbocanegra.panel.colorizer" \
    "/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer"
  do
    if [[ -d "$candidate" ]]; then
      colorizer_root="$candidate"
      break
    fi
  done

  if [[ -f "$ROOT/overlays/defaultDock.layout.js" ]]; then
    local tmp
    tmp="$(mktemp)"
    sed "s|__COLORIZER_ROOT__|${colorizer_root}|g" "$ROOT/overlays/defaultDock.layout.js" >"$tmp"
    dest_install "$tmp" \
      "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultDock/contents/layout.js"
    rm -f "$tmp"
  fi
  if [[ -f "$ROOT/overlays/defaultPanel.layout.js" ]]; then
    local tmp2
    tmp2="$(mktemp)"
    sed "s|__COLORIZER_ROOT__|${colorizer_root}|g" "$ROOT/overlays/defaultPanel.layout.js" >"$tmp2"
    dest_install "$tmp2" \
      "$SHARE/plasma/layout-templates/org.garuda.desktop.defaultPanel/contents/layout.js"
    rm -f "$tmp2"
  fi
}

install_sweet() {
  local SHARE
  SHARE="$(_rice_share)"
  local sweet="$BUILD_DIR/sweet"
  local sweet_kde="$BUILD_DIR/sweet-kde"
  local kde="$sweet/kde"
  [[ -d "$kde" ]] || die "Sweet theme (nova/kde) not fetched"

  log "Installing Sweet theme assets..."

  # Aurorae window decorations
  dest_mkdir "$SHARE/aurorae/themes"
  [[ -d "$kde/aurorae/Sweet-Dark" ]] && \
    dest_cp_tree "$kde/aurorae/Sweet-Dark" "$SHARE/aurorae/themes/Sweet-Dark"
  [[ -d "$kde/aurorae/Sweet-Dark-transparent" ]] && \
    dest_cp_tree "$kde/aurorae/Sweet-Dark-transparent" "$SHARE/aurorae/themes/Sweet-Dark-transparent"

  # Color schemes
  if [[ -d "$kde/colorschemes" ]]; then
    dest_mkdir "$SHARE/color-schemes"
    dest_cp_tree "$kde/colorschemes" "$SHARE/color-schemes"
  fi

  # Kvantum
  [[ -d "$kde/Kvantum/Sweet" ]] && dest_cp_tree "$kde/Kvantum/Sweet" "$SHARE/Kvantum/Sweet"
  [[ -d "$kde/Kvantum/Sweet-transparent-toolbar" ]] && \
    dest_cp_tree "$kde/Kvantum/Sweet-transparent-toolbar" "$SHARE/Kvantum/Sweet-transparent-toolbar"

  # Cursors (prebuilt on nova)
  if [[ -d "$kde/cursors/Sweet-cursors" ]]; then
    dest_cp_tree "$kde/cursors/Sweet-cursors" "$SHARE/icons/Sweet-cursors"
  fi

  # Konsole
  if [[ -d "$kde/konsole" ]]; then
    dest_mkdir "$SHARE/konsole"
    dest_cp_tree "$kde/konsole" "$SHARE/konsole"
  fi

  # Sweet look-and-feel (optional; Dr460nized is primary)
  if [[ -d "$kde/look-and-feel" ]]; then
    dest_cp_tree "$kde/look-and-feel" "$SHARE/plasma/look-and-feel/Sweet"
  fi

  # SDDM
  if [[ -d "$kde/sddm" ]]; then
    dest_cp_tree "$kde/sddm" "$SHARE/sddm/themes/Sweet"
  fi

  # GTK Sweet-Dark from release tarball
  local gtk_src="$BUILD_DIR/sweet-gtk-dark/Sweet-Dark"
  if [[ -d "$gtk_src" ]]; then
    dest_cp_tree "$gtk_src" "$SHARE/themes/Sweet-Dark"
  elif [[ -d "$BUILD_DIR/sweet-gtk-dark" ]]; then
    # tarball may extract differently
    local found
    found="$(find "$BUILD_DIR/sweet-gtk-dark" -maxdepth 2 -type d -name 'Sweet-Dark' | head -1)"
    [[ -n "$found" ]] && dest_cp_tree "$found" "$SHARE/themes/Sweet-Dark"
  fi

  # Also install as "Sweet" alias if only Dark present
  if [[ -d "$SHARE/themes/Sweet-Dark" && ! -d "$SHARE/themes/Sweet" ]]; then
    dest_cp_tree "$SHARE/themes/Sweet-Dark" "$SHARE/themes/Sweet"
  fi

  # Sweet-kde plasma desktoptheme
  if [[ -d "$sweet_kde" ]]; then
    if [[ -f "$sweet_kde/metadata.desktop" || -f "$sweet_kde/metadata.json" ]]; then
      dest_cp_tree "$sweet_kde" "$SHARE/plasma/desktoptheme/Sweet"
    fi
  fi
}

install_icons() {
  local SHARE
  SHARE="$(_rice_share)"
  log "Installing BeautyLine and candy-icons..."
  if [[ -d "$BUILD_DIR/candy-icons" ]]; then
    dest_cp_tree "$BUILD_DIR/candy-icons" "$SHARE/icons/candy-icons"
  fi
  if [[ -d "$BUILD_DIR/beautyline" ]]; then
    # repo root is the icon theme
    if [[ -f "$BUILD_DIR/beautyline/index.theme" ]]; then
      dest_cp_tree "$BUILD_DIR/beautyline" "$SHARE/icons/BeautyLine"
    else
      find "$BUILD_DIR/beautyline" -name 'index.theme' | head -1 | while read -r idx; do
        dest_cp_tree "$(dirname "$idx")" "$SHARE/icons/BeautyLine"
      done
    fi
  fi
}

install_wallpapers() {
  local SHARE
  SHARE="$(_rice_share)"
  log "Installing Garuda wallpapers..."
  local wp="$BUILD_DIR/garuda-wallpapers"
  if [[ -d "$wp" ]]; then
    dest_mkdir "$SHARE/wallpapers/garuda-wallpapers"
    # Copy image files into a flat wallpaper folder + plasma wallpaper dirs if present
    if [[ -d "$wp/usr/share/wallpapers" ]]; then
      dest_cp_tree "$wp/usr/share/wallpapers" "$SHARE/wallpapers"
    else
      dest_cp_tree "$wp" "$SHARE/wallpapers/garuda-wallpapers"
    fi
  fi
}

install_garuda_icons_overlay() {
  local SHARE
  SHARE="$(_rice_share)"
  dest_mkdir "$SHARE/icons/garuda"
  if [[ -d "$ROOT/overlays/garuda-icons" ]]; then
    dest_cp_tree "$ROOT/overlays/garuda-icons" "$SHARE/icons/garuda"
  fi
  # Symlink kickoff icon name used by panel layout
  if [[ -f "$SHARE/icons/garuda/distributor-logo-garuda.svg" ]]; then
    dest_mkdir "$SHARE/icons/hicolor/scalable/apps"
    if [[ -w "$SHARE/icons/hicolor/scalable/apps" ]]; then
      ln -sfn "$SHARE/icons/garuda/distributor-logo-garuda.svg" \
        "$SHARE/icons/hicolor/scalable/apps/distributor-logo-garuda.svg"
    else
      run_as_root ln -sfn "$SHARE/icons/garuda/distributor-logo-garuda.svg" \
        "$SHARE/icons/hicolor/scalable/apps/distributor-logo-garuda.svg"
    fi
  fi
}

install_fastfetch_preset() {
  local SHARE
  SHARE="$(_rice_share)"
  local preset="$ROOT/configs/fastfetch/dr460nized.jsonc"
  local out="$SHARE/fastfetch/presets/dr460nized.jsonc"
  local logo_dir="$SHARE/icons/garuda"
  dest_mkdir "$(dirname "$out")"
  local tmp
  tmp="$(mktemp)"
  sed "s|__GARUDA_ICON_DIR__|${logo_dir}|g" "$preset" >"$tmp"
  dest_install "$tmp" "$out"
  rm -f "$tmp"
}

patch_aurorae_sweet() {
  local SHARE
  SHARE="$(_rice_share)"
  local patch="$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc-dr460nized"
  local target="$SHARE/aurorae/themes/Sweet-Dark/Sweet-Darkrc"
  # Also patch system path if Sweet was installed there by packages
  for t in "$target" "/usr/share/aurorae/themes/Sweet-Dark/Sweet-Darkrc"; do
    local pdir
    pdir="$(dirname "$t")"
    local p="$pdir/Sweet-Darkrc-dr460nized"
    if [[ -f "$patch" && -d "$pdir" ]]; then
      if [[ -w "$pdir" ]]; then
        cp -f "$patch" "$t"
      else
        run_as_root cp -f "$patch" "$t"
      fi
      log "Patched Aurorae Sweet-Darkrc at $t"
    elif [[ -f "$ROOT/overlays/Sweet-Darkrc-dr460nized" && -d "$pdir" ]]; then
      if [[ -w "$pdir" ]]; then
        cp -f "$ROOT/overlays/Sweet-Darkrc-dr460nized" "$t"
      else
        run_as_root cp -f "$ROOT/overlays/Sweet-Darkrc-dr460nized" "$t"
      fi
      log "Patched Aurorae Sweet-Darkrc at $t"
    fi
  done
}

install_themes() {
  local SHARE
  SHARE="$(_rice_share)"
  install_dr460nized_assets
  install_sweet
  install_icons
  install_wallpapers
  install_garuda_icons_overlay
  install_fastfetch_preset
  patch_aurorae_sweet
  if have_cmd gtk-update-icon-cache; then
    gtk-update-icon-cache -f "$SHARE/icons/BeautyLine" 2>/dev/null || true
    gtk-update-icon-cache -f "$SHARE/icons/candy-icons" 2>/dev/null || true
  fi
}
