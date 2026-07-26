#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# powermenu.sh — Menú de energía minimalista Gruvbox con Rofi e íconos SVG
# ─────────────────────────────────────────────────────────────────────────────

THEME="$HOME/.config/rofi/themes/powermenu.rasi"
ICON_DIR="$HOME/.config/rofi/themes/icons"

# ── Opciones con formato Rofi dmenu native icon (\0icon\x1f<path>) ──────────
LOCK="Bloquear\0icon\x1f${ICON_DIR}/lock.svg"
LOGOUT="Cerrar Sesión\0icon\x1f${ICON_DIR}/logout.svg"
REBOOT="Reiniciar\0icon\x1f${ICON_DIR}/reboot.svg"
SHUTDOWN="Apagar\0icon\x1f${ICON_DIR}/shutdown.svg"

# Lista de entradas separadas por salto de línea estándar
ENTRIES="${LOCK}\n${LOGOUT}\n${REBOOT}\n${SHUTDOWN}"

# ── Ejecutar Rofi ─────────────────────────────────────────────────────────────
CHOSEN=$(printf "%b" "$ENTRIES" | rofi \
    -dmenu \
    -theme            "$THEME" \
    -p                "" \
    -show-icons \
    -hover-select \
    -me-select-entry   "" \
    -me-accept-entry   "MousePrimary")

# ── Acciones de Sistema ───────────────────────────────────────────────────────
case "$CHOSEN" in
    "Bloquear")
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
            loginctl lock-session
        else
            i3lock -c 282828
        fi
        ;;

    "Cerrar Sesión")
        loginctl terminate-session ${XDG_SESSION_ID:-} || pkill -KILL -u "$USER"
        ;;

    "Reiniciar")
        systemctl reboot
        ;;

    "Apagar")
        systemctl poweroff
        ;;
esac
