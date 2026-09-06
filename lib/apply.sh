# shellcheck shell=bash
# Apply look-and-feel and merge skel KDE configs into the user home.

apply_skel_configs() {
  local skel="$ROOT/configs/skel"
  log "Backing up existing configs to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"

  local files=(
    .config/kdeglobals
    .config/kwinrc
    .config/kcminputrc
    .config/konsolerc
    .config/kscreenlockerrc
    .config/dolphinrc
    .config/baloofilerc
    .config/katerc
    .config/Kvantum/kvantum.kvconfig
    .config/gtk-3.0/settings.ini
    .config/gtk-3.0/gtk.css
    .config/gtk-3.0/colors.css
    .config/gtk-4.0/settings.ini
    .config/gtk-4.0/gtk.css
    .config/gtk-4.0/colors.css
    .icons/default/index.theme
    .local/share/konsole/Garuda.profile
  )

  local f
  for f in "${files[@]}"; do
    backup_path "$HOME/$f"
    if [[ -f "$skel/$f" ]]; then
      mkdir -p "$(dirname "$HOME/$f")"
      install -m 0644 "$skel/$f" "$HOME/$f"
    fi
  done

  # Fix konsole Command for chosen shell
  local shell_path
  case "${SHELL_CHOICE:-fish}" in
    bash) shell_path="$(command -v bash || echo /bin/bash)" ;;
    *)    shell_path="$(command -v fish || echo /usr/bin/fish)" ;;
  esac
  if [[ -f "$HOME/.local/share/konsole/Garuda.profile" ]]; then
    sed -i "s|^Command=.*|Command=${shell_path}|" "$HOME/.local/share/konsole/Garuda.profile"
  fi
}

apply_lookandfeel() {
  log "Applying Dr460nized look-and-feel (resets panels/dock/wallpaper)..."
  if have_cmd plasma-apply-lookandfeel; then
    plasma-apply-lookandfeel -a Dr460nized || \
      lookandfeeltool -a Dr460nized || \
      warn "plasma-apply-lookandfeel failed; apply Dr460nized manually in System Settings"
  elif have_cmd lookandfeeltool; then
    lookandfeeltool -a Dr460nized || warn "lookandfeeltool failed"
  else
    warn "No look-and-feel tool found; open System Settings → Appearance → Global Theme → Dr460nized"
  fi

  # Ensure key theme bits via plasma helpers when available
  if have_cmd plasma-apply-colorscheme; then
    plasma-apply-colorscheme Sweet 2>/dev/null || true
  fi
  if have_cmd plasma-apply-desktoptheme; then
    plasma-apply-desktoptheme Dr460nized 2>/dev/null || true
  fi
  if have_cmd plasma-apply-cursortheme; then
    plasma-apply-cursortheme Sweet-cursors 2>/dev/null || true
  fi
}

apply_rice() {
  if ! confirm "This will RESET your Plasma panels, dock, and wallpaper to Dr460nized. Continue?"; then
    die "Apply cancelled"
  fi
  apply_skel_configs
  patch_aurorae_sweet
  apply_lookandfeel
  log "Apply complete. Log out/in (or run: plasmashell --replace &) for full effect."
  log "Backup of previous configs: $BACKUP_DIR"
}
