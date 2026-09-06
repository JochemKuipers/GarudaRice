# shellcheck shell=bash
# Install distro packages needed for the rice.

pkg_install() {
  case "$DISTRO_FAMILY" in
    arch)
      run_as_root pacman -S --needed --noconfirm "$@"
      ;;
    fedora)
      run_as_root dnf install -y "$@"
      ;;
    debian)
      run_as_root apt-get update -qq
      run_as_root DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
      ;;
  esac
}

try_pkg_install() {
  pkg_install "$@" || warn "Some packages failed to install: $*"
}

install_starship_fallback() {
  if have_cmd starship; then
    return 0
  fi
  log "Installing starship via official installer..."
  curl -fsSL https://starship.rs/install.sh | run_as_root sh -s -- -y
}

install_nerd_font_fallback() {
  local font_dir
  if [[ "$USER_INSTALL" == "1" ]]; then
    font_dir="$HOME/.local/share/fonts/FiraCodeNerd"
  else
    font_dir="$PREFIX/share/fonts/FiraCodeNerd"
  fi
  if fc-list 2>/dev/null | grep -qi 'FiraCode Nerd'; then
    return 0
  fi
  log "Downloading FiraCode Nerd Font..."
  local zip="$BUILD_DIR/FiraCode.zip"
  download \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FiraCode.zip" \
    "$zip"
  dest_mkdir "$font_dir"
  if [[ -w "$font_dir" ]]; then
    unzip -o -q "$zip" -d "$font_dir"
  else
    run_as_root unzip -o -q "$zip" -d "$font_dir"
  fi
  fc-cache -f "$font_dir" 2>/dev/null || true
}

install_packages() {
  log "Installing packages for $DISTRO_FAMILY..."

  case "$DISTRO_FAMILY" in
    arch)
      try_pkg_install \
        kvantum kvantum-qt5 \
        fish starship bat eza fzf fastfetch \
        ttf-fira-sans ttf-firacode-nerd \
        git curl unzip base-devel \
        cmake extra-cmake-modules qt6-base qt6-declarative \
        plasma-workspace konsole
      # kvantum-qt5 optional on newer; ignore failure already handled
      ;;
    fedora)
      try_pkg_install \
        kvantum fish starship bat eza fzf fastfetch \
        mozilla-fira-sans-fonts \
        git curl unzip \
        cmake extra-cmake-modules \
        qt6-qtbase-devel qt6-qtdeclarative-devel \
        plasma-workspace konsole
      # Nerd font often missing
      install_nerd_font_fallback
      ;;
    debian)
      try_pkg_install \
        qt6-style-kvantum fish bat eza fzf fastfetch \
        fonts-fira-sans \
        git curl unzip \
        cmake extra-cmake-modules \
        qt6-base-dev qt6-declarative-dev \
        plasma-workspace konsole
      # package names vary; try kvantum alt
      pkg_install qt6-style-kvantum 2>/dev/null || \
        pkg_install kvantum 2>/dev/null || \
        warn "Install Kvantum manually if missing"
      install_starship_fallback
      install_nerd_font_fallback
      ;;
  esac

  have_cmd fish || die "fish shell failed to install"
  have_cmd starship || install_starship_fallback
  have_cmd kvantummanager || have_cmd kvantum || warn "Kvantum may be missing; Qt theming might fall back"
}
