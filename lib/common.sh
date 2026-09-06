# shellcheck shell=bash
# Common helpers. Sourced by install.sh.

set -euo pipefail

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

confirm() {
  local msg="$1"
  if [[ "${ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi
  printf '%s [y/N] ' "$msg"
  local ans
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

backup_path() {
  local src="$1"
  local dest="$BACKUP_DIR/${src#"$HOME"/}"
  if [[ -e "$src" || -L "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
  fi
}

install_file() {
  local src="$1" dest="$2" mode="${3:-0644}"
  mkdir -p "$(dirname "$dest")"
  install -m "$mode" "$src" "$dest"
}

install_tree() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  cp -a "$src"/. "$dest"/
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "Need root privileges (sudo) to install to $PREFIX"
  fi
}

# Install into PREFIX (system or user). Uses sudo when PREFIX is not writable.
dest_install() {
  local src="$1" dest="$2" mode="${3:-0644}"
  if [[ -w "$(dirname "$dest")" ]] 2>/dev/null || mkdir -p "$(dirname "$dest")" 2>/dev/null; then
    install_file "$src" "$dest" "$mode"
  else
    run_as_root mkdir -p "$(dirname "$dest")"
    run_as_root install -m "$mode" "$src" "$dest"
  fi
}

dest_mkdir() {
  local dir="$1"
  if mkdir -p "$dir" 2>/dev/null; then
    return 0
  fi
  run_as_root mkdir -p "$dir"
}

dest_cp_tree() {
  local src="$1" dest="$2"
  dest_mkdir "$dest"
  if [[ -w "$dest" ]]; then
    cp -a "$src"/. "$dest"/
  else
    run_as_root cp -a "$src"/. "$dest"/
  fi
}

dest_rm() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    if [[ -w "$(dirname "$path")" ]]; then
      rm -rf "$path"
    else
      run_as_root rm -rf "$path"
    fi
  fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

_rice_share() {
  if [[ "${USER_INSTALL:-0}" == "1" ]]; then
    echo "${HOME}/.local/share"
  else
    echo "${PREFIX:-/usr/local}/share"
  fi
}

download() {
  local url="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  if have_cmd curl; then
    curl -fsSL -o "$out" "$url"
  elif have_cmd wget; then
    wget -q -O "$out" "$url"
  else
    die "Need curl or wget to download assets"
  fi
}

extract_tar() {
  local archive="$1" dest="$2"
  mkdir -p "$dest"
  tar -xf "$archive" -C "$dest" --strip-components=1 2>/dev/null \
    || tar -xf "$archive" -C "$dest"
}
