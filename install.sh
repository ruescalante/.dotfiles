#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${DOTFILES_HOME:-${HOME:-}}"

if [[ -z "$HOME_DIR" ]]; then
  printf '[dotfiles] HOME is not set and DOTFILES_HOME is empty\n' >&2
  exit 1
fi

links=(
  ".bashrc"
  ".gitconfig"
  ".p10k.zsh"
  ".zshrc"
  ".config/foot"
  ".config/hypr"
  ".config/rofi"
  ".config/sway"
  ".config/Thunar"
  ".config/waybar"
  ".local/share/fonts"
)

arch_packages=(
  zsh
  curl
  wget
  git
  which
)

info() {
  printf '[dotfiles] %s\n' "$1"
}

warn() {
  printf '[dotfiles] %s\n' "$1" >&2
}

is_arch() {
  [[ -f /etc/arch-release ]] || command -v pacman >/dev/null 2>&1
}

install_arch_packages() {
  if ! is_arch; then
    warn "skipping Arch bootstrap: pacman not available"
    return 0
  fi

  info "installing Arch base packages"
  sudo pacman -S --needed --noconfirm "${arch_packages[@]}"
}

install_fzf() {
  local fzf_dir="$HOME_DIR/.fzf"

  if [[ -x "$fzf_dir/bin/fzf" ]]; then
    info "fzf already installed"
    return 0
  fi

  if [[ ! -d "$fzf_dir" ]]; then
    info "cloning fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"
  fi

  info "installing fzf binary"
  "$fzf_dir/install" --bin
}

install_zoxide() {
  local zoxide_bin_dir="$HOME_DIR/.local/bin"

  if command -v zoxide >/dev/null 2>&1; then
    info "zoxide already installed"
    return 0
  fi

  info "installing zoxide"
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$zoxide_bin_dir"
}

resolve_target_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "$SUDO_USER"
    return 0
  fi

  local current_user
  current_user="$(id -un)"
  if [[ "$current_user" == "root" ]]; then
    printf '%s\n' ""
    return 0
  fi

  printf '%s\n' "$current_user"
}

set_default_shell() {
  local target_user
  target_user="$(resolve_target_user)"

  if [[ -z "$target_user" ]]; then
    warn "skipping shell change: unable to resolve a non-root target user"
    return 0
  fi

  if ! command -v chsh >/dev/null 2>&1; then
    warn "skipping shell change: chsh not found"
    return 0
  fi

  local current_shell
  current_shell="$(getent passwd "$target_user" | cut -d: -f7)"

  if [[ "$current_shell" == */zsh ]]; then
    info "shell already points to zsh for ${target_user}"
    return 0
  fi

  if [[ ! -x /usr/bin/zsh ]]; then
    warn "skipping shell change: /usr/bin/zsh not found"
    return 0
  fi

  info "changing default shell to zsh for ${target_user}"
  chsh -s /usr/bin/zsh "$target_user"
}

ensure_parent_dir() {
  local destination="$1"
  local parent_dir
  parent_dir="$(dirname "$destination")"

  mkdir -p "$parent_dir"
}

link_path() {
  local source="$1"
  local destination="$2"

  if [[ ! -e "$source" ]]; then
    printf '[dotfiles] missing source: %s\n' "$source" >&2
    return 1
  fi

  ensure_parent_dir "$destination"

  if [[ -L "$destination" ]]; then
    local current_target
    current_target="$(readlink "$destination")"
    if [[ "$current_target" == "$source" ]]; then
      info "already linked: $destination"
      return 0
    fi
    rm "$destination"
  elif [[ -e "$destination" ]]; then
    rm -rf "$destination"
  fi

  ln -s "$source" "$destination"
  info "linked: $destination -> $source"
}

main() {
  info "repo root: $REPO_ROOT"
  info "home dir: $HOME_DIR"

  install_arch_packages
  install_fzf
  install_zoxide
  set_default_shell

  for relative_path in "${links[@]}"; do
    link_path "$REPO_ROOT/$relative_path" "$HOME_DIR/$relative_path"
  done

  info "done"
}

main "$@"