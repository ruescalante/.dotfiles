#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# powermenu.sh — Menú de energía con rofi
#
# Instalación:
#   mkdir -p ~/.config/rofi/scripts
#   cp powermenu.sh ~/.config/rofi/scripts/
#   chmod +x ~/.config/rofi/scripts/powermenu.sh
#
# Atajo de teclado (ejemplo i3/sway):
#   bindsym $mod+Shift+e exec ~/.config/rofi/scripts/powermenu.sh
#
# Dependencias:
#   - rofi
#   - Un compositor para la transparencia (picom, sway, hyprland…)
#   - Un tema de íconos instalado (papirus-icon-theme recomendado)
#   - systemctl (systemd) para apagar/reiniciar
#   - Un locker: i3lock | swaylock | loginctl lock-session
# ─────────────────────────────────────────────────────────────────────────────

THEME="$HOME/.config/rofi/themes/powermenu.rasi"

# ── Opciones ──────────────────────────────────────────────────────────────
# Formato:  "Texto visible\0icon\x1f<nombre-icono-freedesktop>"
# Los nombres de ícono provienen de tu tema (Papirus los incluye todos).
# Rofi los muestra arriba del texto gracias a -show-icons.

SHUTDOWN="Apagar\0icon\x1fsystem-shutdown"
REBOOT="Reiniciar\0icon\x1fsystem-reboot"
LOCK="Bloquear\0icon\x1fsystem-lock-screen"

# Orden de los botones (izquierda → derecha)
ENTRIES="$LOCK\n$REBOOT\n$SHUTDOWN"

# ── Rofi ──────────────────────────────────────────────────────────────────
CHOSEN=$(printf "$ENTRIES" | rofi \
    -dmenu \
    -theme      "$THEME" \
    -p          "" \
    -no-custom \
    -markup-rows \
    -show-icons \
    -icon-theme "Papirus-Dark" \
    -hover-select \
    -me-select-entry   "" \
    -me-accept-entry   "MousePrimary")

# ── Acción ────────────────────────────────────────────────────────────────
case "$CHOSEN" in

    "Apagar")
        systemctl poweroff
        ;;

    "Reiniciar")
        systemctl reboot
        ;;

    "Bloquear")
        # Descomenta el locker que uses:

        # ── Wayland ──────────────────────────────────────────────────────
        # swaylock                           # sway / wlroots
        # hyprlock                           # hyprland
        # loginctl lock-session              # cualquier sesión systemd

        # ── X11 ──────────────────────────────────────────────────────────
        # i3lock -c 282828                   # color de fondo gruvbox
        # i3lock-fancy
        # betterlockscreen -l dim

        # ── Universal (detecta X11 o Wayland automáticamente) ────────────
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
            loginctl lock-session
        else
            i3lock -c 282828
        fi
        ;;

esac
