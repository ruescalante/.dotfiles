#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${DOTFILES_HOME:-${HOME:-}}"
KEYBOARD_LAYOUT=""

if [[ -z "$HOME_DIR" ]]; then
  printf '[dotfiles] HOME is not set and DOTFILES_HOME is empty\n' >&2
  exit 1
fi

links=(
  ".bashrc"
  ".gitconfig"
  ".p10k.zsh"
  ".zshrc"
  ".scripts"
  ".config/foot"
  ".config/hypr"
  ".config/mako"
  ".config/rofi"
  ".config/sway"
  ".config/swaylock"
  ".config/Thunar"
  ".config/waybar"
  ".local/share/fonts"
)

arch_packages=(
  base-devel
  zsh
  git
  wget
  curl
  eza
  fastfetch
  htop
  btop
  neovim
  vim
  sway
  swaylock
  swaybg
  waybar
  mako
  rofi
  foot
  grim
  slurp
  ffmpeg
  wl-clipboard
  thunar
  tumbler
  ffmpegthumbnailer
  polkit-gnome
  sound-theme-freedesktop
  xdg-desktop-portal
  xdg-desktop-portal-gtk
  xdg-desktop-portal-wlr
  xorg-xwayland
  noto-fonts
  noto-fonts-emoji
  playerctl
  brightnessctl
  wireplumber
  mpv
  yt-dlp
  ristretto
)

aur_packages=(
  microsoft-edge-stable-bin
  visual-studio-code-bin
  zen-browser-bin
)

info() {
  printf '[dotfiles] %s\n' "$1"
}

warn() {
  printf '[dotfiles] %s\n' "$1" >&2
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --laptop)
        KEYBOARD_LAYOUT="latam"
        shift
        ;;
      --pc)
        KEYBOARD_LAYOUT="us"
        shift
        ;;
      --keyboard)
        if [[ -n "${2:-}" ]]; then
          KEYBOARD_LAYOUT="$2"
          shift 2
        else
          warn "missing layout value for --keyboard"
          shift
        fi
        ;;
      --help|-h)
        printf "Usage: %s [OPTIONS]\n" "$0"
        printf "Options:\n"
        printf "  --laptop            Set keyboard layout to latam (laptop default)\n"
        printf "  --pc                Set keyboard layout to us (PC default)\n"
        printf "  --keyboard LAYOUT   Set specific keyboard layout (e.g. latam, us)\n"
        printf "  -h, --help          Show this help message\n"
        exit 0
        ;;
      *)
        warn "unknown argument: $1"
        shift
        ;;
    esac
  done
}

is_arch() {
  [[ -f /etc/arch-release ]] || command -v pacman >/dev/null 2>&1
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

run_as_root() {
  if [[ "$(id -un)" == "root" ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    warn "cannot execute root command: sudo is not installed and script is not running as root"
    return 1
  fi
}

install_arch_packages() {
  if ! is_arch; then
    warn "skipping Arch bootstrap: pacman not available"
    return 0
  fi

  info "installing Arch base packages"
  run_as_root pacman -S --needed --noconfirm "${arch_packages[@]}"
}

install_yay_and_aur_packages() {
  if ! is_arch; then
    warn "skipping AUR packages: pacman not available"
    return 0
  fi

  local target_user
  target_user="$(resolve_target_user)"

  if [[ -z "$target_user" ]]; then
    warn "skipping AUR installation: running as pure root without a non-root target user (makepkg cannot run as root)"
    return 0
  fi

  local run_as_user=()
  if [[ "$(id -un)" == "root" && -n "$target_user" ]]; then
    run_as_user=(sudo -u "$target_user")
  fi

  if ! command -v yay >/dev/null 2>&1; then
    info "yay is not installed. Installing yay from AUR..."
    local build_dir="/tmp/yay_build_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"

    if [[ -n "$target_user" ]]; then
      chown -R "$target_user" "$build_dir"
    fi

    "${run_as_user[@]}" git clone https://aur.archlinux.org/yay.git "$build_dir"
    (
      cd "$build_dir"
      "${run_as_user[@]}" makepkg -si --noconfirm
    )
    rm -rf "$build_dir"
  fi

  if command -v yay >/dev/null 2>&1; then
    info "installing AUR packages with yay..."
    "${run_as_user[@]}" yay -S --needed --noconfirm "${aur_packages[@]}"
  else
    warn "failed to install or locate yay. Skipping AUR packages installation."
  fi
}

detect_keyboard_layout() {
  if [[ -n "$KEYBOARD_LAYOUT" ]]; then
    return 0
  fi

  # Interactive choice if running in terminal
  if [[ -t 0 ]]; then
    info "Select keyboard layout for Sway:"
    printf "  1) Laptop (latam)\n"
    printf "  2) PC (us)\n"
    read -r -p "[dotfiles] Enter choice [1-2] (default: 1): " choice
    case "$choice" in
      2) KEYBOARD_LAYOUT="us" ;;
      *) KEYBOARD_LAYOUT="latam" ;;
    esac
    return 0
  fi

  # Non-interactive chassis detection
  if [[ -f /sys/class/dmi/id/chassis_type ]]; then
    local chassis
    chassis="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "")"
    case "$chassis" in
      8|9|10|14|31|32)
        KEYBOARD_LAYOUT="latam"
        ;;
      *)
        KEYBOARD_LAYOUT="us"
        ;;
    esac
  else
    KEYBOARD_LAYOUT="us"
  fi
}

configure_keyboard() {
  detect_keyboard_layout
  info "configuring Sway keyboard layout to: ${KEYBOARD_LAYOUT}"

  # Clean up legacy in-repo local file if it exists
  local legacy_keyboard_file="$HOME_DIR/.config/sway/config.d/99-keyboard-local.conf"
  if [[ -e "$legacy_keyboard_file" ]]; then
    rm -f "$legacy_keyboard_file"
  fi

  # Write to external path outside of symlinked repo tree
  local sway_external_keyboard_file="$HOME_DIR/.config/sway-keyboard.conf"
  ensure_parent_dir "$sway_external_keyboard_file"

  cat <<EOF > "$sway_external_keyboard_file"
# Auto-generated by dotfiles installer for local machine
input type:keyboard {
    xkb_layout "${KEYBOARD_LAYOUT}"
}
EOF

  info "written external keyboard config: ${sway_external_keyboard_file}"
}

setup_zprofile() {
  local zprofile_dest="$HOME_DIR/.zprofile"
  if [[ "$KEYBOARD_LAYOUT" == "us" ]]; then
    info "PC detected (US keyboard): linking .zprofile for NVIDIA/Wayland environment"
    link_path "$REPO_ROOT/.zprofile" "$zprofile_dest"
  else
    info "Laptop detected (latam keyboard): skipping .zprofile (NVIDIA settings not required)"
    if [[ -L "$zprofile_dest" ]]; then
      local link_target
      link_target="$(readlink "$zprofile_dest")"
      if [[ "$link_target" == "$REPO_ROOT/.zprofile" ]]; then
        info "removing PC-specific .zprofile symlink on laptop"
        rm "$zprofile_dest"
      fi
    fi
  fi
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
    local backup_path="${destination}.bak.$(date +%s)"
    info "creating backup for existing path: ${destination} -> ${backup_path}"
    mv "$destination" "$backup_path"
  fi

  ln -s "$source" "$destination"
  info "linked: $destination -> $source"
}

main() {
  parse_args "$@"

  info "repo root: $REPO_ROOT"
  info "home dir: $HOME_DIR"

  install_arch_packages
  install_yay_and_aur_packages
  install_fzf
  install_zoxide
  set_default_shell

  for relative_path in "${links[@]}"; do
    link_path "$REPO_ROOT/$relative_path" "$HOME_DIR/$relative_path"
  done

  configure_keyboard
  setup_zprofile

  info "done"
}

main "$@"