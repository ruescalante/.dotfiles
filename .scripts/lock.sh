#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# lock.sh — Captura con blur intenso + cortina negra (dark glass), candado y fecha
# ─────────────────────────────────────────────────────────────────────────────

TMP_IMG="/tmp/swaylock_screen.png"
TMP_BLUR="/tmp/swaylock_blur.png"

# Fecha actual formateada en español (ej. "Domingo, 26 de julio de 2026")
DATE_STR=$(LC_TIME=es_SV.utf8 date +"%A, %d de %B de %Y" 2>/dev/null | sed 's/^./\U&/' || date +"%d/%m/%Y")
ICON_PATH="$HOME/.config/rofi/themes/icons/lock.svg"

# Capturar pantalla actual con grim
grim "$TMP_IMG" 2>/dev/null

if [ -f "$TMP_IMG" ]; then
    # Blur intenso (boxblur=18:4) + cortina translúcida negra (drawbox=color=black@0.45), icono 96x96 y texto de estado/fecha
    if [ -f "$ICON_PATH" ]; then
        ffmpeg -y -loglevel quiet -i "$TMP_IMG" -i "$ICON_PATH" \
            -filter_complex "[0:v]boxblur=18:4,drawbox=color=black@0.45:t=fill[bg];[1:v]scale=96:96[icon];[bg][icon]overlay=(W-w)/2:(H-h)/2[with_icon];[with_icon]drawtext=fontfile=/usr/share/fonts/noto/NotoSans-Bold.ttf:text='Bloqueado':fontcolor=0xebdbb2ff:fontsize=32:x=(w-text_w)/2:y=h-100[with_title];[with_title]drawtext=fontfile=/usr/share/fonts/noto/NotoSans-Regular.ttf:text='${DATE_STR}':fontcolor=0xa89984ff:fontsize=20:x=(w-text_w)/2:y=h-50[out]" \
            -map "[out]" -frames:v 1 "$TMP_BLUR"
    else
        ffmpeg -y -loglevel quiet -i "$TMP_IMG" \
            -vf "boxblur=18:4,drawbox=color=black@0.45:t=fill,drawtext=fontfile=/usr/share/fonts/noto/NotoSans-Bold.ttf:text='Bloqueado':fontcolor=0xebdbb2ff:fontsize=32:x=(w-text_w)/2:y=h-100,drawtext=fontfile=/usr/share/fonts/noto/NotoSans-Regular.ttf:text='${DATE_STR}':fontcolor=0xa89984ff:fontsize=20:x=(w-text_w)/2:y=h-50" \
            -frames:v 1 "$TMP_BLUR"
    fi
    
    swaylock -i "$TMP_BLUR"
    rm -f "$TMP_IMG" "$TMP_BLUR"
else
    swaylock
fi
