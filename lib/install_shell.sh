# shellcheck shell=bash
# Install fish/bash defaults, starship, konsole profile.

install_shell_system_defaults() {
  local SHARE RICE_SHARE
  SHARE="$(_rice_share)"
  RICE_SHARE="$SHARE/garuda-rice"

  dest_mkdir "$RICE_SHARE/fish"
  dest_mkdir "$RICE_SHARE/bash"
  dest_mkdir "$RICE_SHARE/distro"

  dest_install "$ROOT/configs/shell/fish/config.fish" "$RICE_SHARE/fish/config.fish"
  dest_install "$ROOT/configs/shell/bash/bashrc" "$RICE_SHARE/bash/bashrc"
  dest_install "$ROOT/configs/shell/distro/arch.inc" "$RICE_SHARE/distro/arch.inc"
  dest_install "$ROOT/configs/shell/distro/fedora.inc" "$RICE_SHARE/distro/fedora.inc"
  dest_install "$ROOT/configs/shell/distro/debian.inc" "$RICE_SHARE/distro/debian.inc"
  dest_install "$ROOT/configs/shell/distro/arch.fish" "$RICE_SHARE/distro/arch.fish"
  dest_install "$ROOT/configs/shell/distro/fedora.fish" "$RICE_SHARE/distro/fedora.fish"
  dest_install "$ROOT/configs/shell/distro/debian.fish" "$RICE_SHARE/distro/debian.fish"

  local stamp
  stamp="$(mktemp)"
  printf '%s\n' "$DISTRO_FAMILY" >"$stamp"
  dest_install "$stamp" "$RICE_SHARE/distro/current"
  rm -f "$stamp"
}

install_starship_config() {
  local dest="$HOME/.config/starship.toml"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    backup_path "$dest"
  fi
  install -m 0644 "$ROOT/configs/shell/common/starship.toml" "$dest"
}

install_fish_user() {
  local SHARE RICE_SHARE
  SHARE="$(_rice_share)"
  RICE_SHARE="$SHARE/garuda-rice"
  local dest="$HOME/.config/fish/config.fish"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]]; then
    backup_path "$dest"
  fi
  cat >"$dest" <<EOF
# GarudaRice fish stub — defaults live in $RICE_SHARE/fish/config.fish
source $RICE_SHARE/fish/config.fish

# -- Insert customizations below this line! --

__garuda_rice_fastfetch
EOF
}

install_bash_user() {
  local SHARE RICE_SHARE
  SHARE="$(_rice_share)"
  RICE_SHARE="$SHARE/garuda-rice"
  local fragment="$HOME/.bashrc_garuda_rice"
  cat >"$fragment" <<EOF
# GarudaRice bash stub — defaults live in $RICE_SHARE/bash/bashrc
[[ -f $RICE_SHARE/bash/bashrc ]] && source $RICE_SHARE/bash/bashrc
EOF

  local bashrc="$HOME/.bashrc"
  if [[ -f "$bashrc" ]]; then
    backup_path "$bashrc"
    if ! grep -q 'bashrc_garuda_rice' "$bashrc" 2>/dev/null; then
      printf '\n# GarudaRice\n[[ -f ~/.bashrc_garuda_rice ]] && source ~/.bashrc_garuda_rice\n' >>"$bashrc"
    fi
  else
    printf '# GarudaRice\n[[ -f ~/.bashrc_garuda_rice ]] && source ~/.bashrc_garuda_rice\n' >"$bashrc"
  fi
}

install_konsole() {
  local SHARE
  SHARE="$(_rice_share)"
  local kshare="$SHARE/konsole"
  dest_mkdir "$kshare"
  if [[ -f "$ROOT/configs/konsole/Sweet.colorscheme" ]]; then
    dest_install "$ROOT/configs/konsole/Sweet.colorscheme" "$kshare/Sweet.colorscheme"
  fi

  local profile_src="$ROOT/configs/konsole/Garuda.profile"
  local profile_user="$HOME/.local/share/konsole/Garuda.profile"
  mkdir -p "$(dirname "$profile_user")"
  if [[ -f "$profile_user" ]]; then
    backup_path "$profile_user"
  fi

  local shell_path="/usr/bin/fish"
  case "${SHELL_CHOICE:-fish}" in
    bash) shell_path="$(command -v bash || echo /bin/bash)" ;;
    fish) shell_path="$(command -v fish || echo /usr/bin/fish)" ;;
  esac

  local tmp
  tmp="$(mktemp)"
  sed "s|^Command=.*|Command=${shell_path}|" "$profile_src" >"$tmp"
  install -m 0644 "$tmp" "$profile_user"
  rm -f "$tmp"

  dest_install "$profile_user" "$SHARE/konsole/Garuda.profile" 2>/dev/null || true

  local konsolerc="$HOME/.config/konsolerc"
  mkdir -p "$(dirname "$konsolerc")"
  if [[ -f "$konsolerc" ]]; then
    backup_path "$konsolerc"
  fi
  install -m 0644 "$ROOT/configs/skel/.config/konsolerc" "$konsolerc"
}

install_shell() {
  # Ensure backup dir exists when shell install backs up configs
  mkdir -p "${BACKUP_DIR:-$HOME/.garuda-rice-backup}"
  BACKUP_DIR="${BACKUP_DIR:-$HOME/.garuda-rice-backup}"
  install_shell_system_defaults
  install_starship_config
  install_fish_user
  install_bash_user
  install_konsole
  log "Shell configs installed (fish + bash). Konsole default shell: ${SHELL_CHOICE:-fish}"
}
