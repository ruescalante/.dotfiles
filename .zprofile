export WLR_NO_HARDWARE_CURSORS=1
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBVA_DRIVER_NAME=nvidia
export XDG_CURRENT_DESKTOP=sway
export MOZ_ENABLE_WAYLAND=1

# Added by Toolbox App
if [ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]; then
  export PATH="$PATH:$HOME/.local/share/JetBrains/Toolbox/scripts"
fi

# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
