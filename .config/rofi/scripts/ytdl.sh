#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ytdl.sh — Descargador de vídeos/audio con Rofi dmenu e yt-dlp
# ─────────────────────────────────────────────────────────────────────────────

THEME="$HOME/.config/rofi/themes/ytdl.rasi"
DOWNLOAD_DIR="$HOME/Downloads/yt-dlp"

mkdir -p "$DOWNLOAD_DIR"

# 1. Obtener URL del portapapeles (Wayland o X11)
CLIPBOARD_URL=""
if command -v wl-paste &>/dev/null; then
    CLIPBOARD_URL=$(wl-paste 2>/dev/null)
elif command -v xclip &>/dev/null; then
    CLIPBOARD_URL=$(xclip -selection clipboard -o 2>/dev/null)
elif command -v xsel &>/dev/null; then
    CLIPBOARD_URL=$(xsel -b 2>/dev/null)
fi

# Validar si el contenido del portapapeles parece una URL
if [[ ! "$CLIPBOARD_URL" =~ ^https?:// ]]; then
    CLIPBOARD_URL=""
fi

# 2. Rofi dmenu para pedir/confirmar URL
if [ -n "$CLIPBOARD_URL" ]; then
    URL=$(rofi -dmenu -theme "$THEME" -p "🔗 URL" -filter "$CLIPBOARD_URL")
else
    URL=$(rofi -dmenu -theme "$THEME" -p "🔗 URL")
fi

# Si el usuario cancela o deja vacío, salir
[ -z "$URL" ] && exit 0

# 3. Selección de formato de descarga
OPTIONS="🎬 Video (Mejor Calidad)\n🎬 Video (1080p)\n🎬 Video (720p)\n🎵 Audio MP3 (320k)\n🎵 Audio Original (Mejor Calidad)"
FORMAT_CHOICE=$(printf "$OPTIONS" | rofi -dmenu -theme "$THEME" -p "⚡ Formato")

[ -z "$FORMAT_CHOICE" ] && exit 0

# 4. Configurar flags de yt-dlp según la opción seleccionada
case "$FORMAT_CHOICE" in
    "🎬 Video (Mejor Calidad)")
        YTDLP_ARGS=(-f "bestvideo+bestaudio/best" --merge-output-format mp4)
        ;;
    "🎬 Video (1080p)")
        YTDLP_ARGS=(-f "bestvideo[height<=1080]+bestaudio/best" --merge-output-format mp4)
        ;;
    "🎬 Video (720p)")
        YTDLP_ARGS=(-f "bestvideo[height<=720]+bestaudio/best" --merge-output-format mp4)
        ;;
    "🎵 Audio MP3 (320k)")
        YTDLP_ARGS=(-x --audio-format mp3 --audio-quality 0)
        ;;
    "🎵 Audio Original (Mejor Calidad)")
        YTDLP_ARGS=(-x)
        ;;
    *)
        exit 1
        ;;
esac

# 5. Ejecutar la descarga en segundo plano emitiendo notificaciones con barra de progreso
(
    shopt -s lastpipe

    # Prefijo temporal para guardar la miniatura
    THUMB_PREFIX="/tmp/ytdl_thumb_$$"

    # Notificación inicial instantánea (aparición inmediata en Mako con sonido)
    NOTIF_ID=$(notify-send -a "yt-dlp" -p -i video-x-generic -h int:value:0 "yt-dlp" "⏳ Iniciando descarga...\nObteniendo información...")

    # Obtener el título y la ruta esperada de archivo en una sola consulta
    INFO=$(yt-dlp --cookies-from-browser edge "${YTDLP_ARGS[@]}" --print title --print filename -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" "$URL" 2>/dev/null)
    TITLE=$(echo "$INFO" | head -n 1)
    EXPECTED_FILE=$(echo "$INFO" | sed -n '2p')

    [ -z "$TITLE" ] && TITLE="archivo"

    # Determinar si ya existe un archivo con el mismo nombre en la carpeta de descargas
    OUTPUT_TEMPLATE="$DOWNLOAD_DIR/%(title)s.%(ext)s"
    if [ -n "$EXPECTED_FILE" ]; then
        BASE_FILE="${EXPECTED_FILE%.*}"
        if ls "${BASE_FILE}".* &>/dev/null; then
            # El archivo ya existe: cambiar la plantilla para incluir ID y timestamp
            OUTPUT_TEMPLATE="$DOWNLOAD_DIR/%(title)s [%(id)s - %(epoch)s].%(ext)s"
        fi
    fi

    # Actualizar la notificación con el título real obtenido (silencioso)
    notify-send -a "yt-dlp-progress" -r "$NOTIF_ID" -i video-x-generic -h int:value:0 "yt-dlp" "⏳ Descargando: 0%\n$TITLE"

    OUTPUT=""
    STREAM_COUNT=0
    MAX_PCT=0
    LAST_RAW_PCT=0

    # Bucle de captura de salida y progreso en tiempo real (Algoritmo Multiflujo Fluido)
    yt-dlp --cookies-from-browser edge "${YTDLP_ARGS[@]}" --newline --progress-template "%(progress._percent_str)s" --write-thumbnail --convert-thumbnails jpg -o "thumbnail:$THUMB_PREFIX" -o "$OUTPUT_TEMPLATE" "$URL" 2>&1 | while IFS= read -r line; do
        OUTPUT+="$line"$'\n'
        if [[ "$line" =~ ([0-9]+)(\.[0-9]+)?% ]]; then
            RAW_PCT="${BASH_REMATCH[1]}"
            if [ "$RAW_PCT" -lt 25 ] && [ "$LAST_RAW_PCT" -gt 75 ]; then
                STREAM_COUNT=$((STREAM_COUNT + 1))
            fi
            LAST_RAW_PCT="$RAW_PCT"

            if [ "$STREAM_COUNT" -eq 0 ]; then
                PCT=$(( (RAW_PCT * 85) / 100 ))
            else
                PCT=$(( 85 + (RAW_PCT * 13) / 100 ))
            fi

            if [ "$PCT" -gt "$MAX_PCT" ] && [ "$PCT" -le 99 ]; then
                MAX_PCT="$PCT"
                notify-send -a "yt-dlp-progress" -r "$NOTIF_ID" -i video-x-generic -h "int:value:$MAX_PCT" "yt-dlp" "⏳ Descargando: ${MAX_PCT}%\n$TITLE"
            fi
        fi
    done

    EXIT_CODE=${PIPESTATUS[0]}

    # Buscar la miniatura generada por yt-dlp (ej: /tmp/ytdl_thumb_123.jpg)
    ICON_PATH=$(ls ${THUMB_PREFIX}* 2>/dev/null | head -n 1)

    # Si yt-dlp no descargó miniatura, intentar extraer fotograma con ffmpeg
    if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
        LAST_FILE=$(ls -t "$DOWNLOAD_DIR"/* 2>/dev/null | head -n 1)
        if [ -n "$LAST_FILE" ] && [ -f "$LAST_FILE" ]; then
            ffmpeg -y -ss 00:00:02 -i "$LAST_FILE" -vframes 1 -q:v 2 "$THUMB_PREFIX.jpg" 2>/dev/null
            if [ -f "$THUMB_PREFIX.jpg" ]; then
                ICON_PATH="$THUMB_PREFIX.jpg"
            fi
        fi
    fi

    if [ -z "$ICON_PATH" ] || [ ! -f "$ICON_PATH" ]; then
        ICON_PATH="downloaded"
    fi

    if [ $EXIT_CODE -eq 0 ]; then
        ACTION=$(notify-send -a "yt-dlp" -r "$NOTIF_ID" -i "$ICON_PATH" -h int:value:100 --action=default="Abrir carpeta" "yt-dlp" "✅ Descarga completada:\n$TITLE\n\n📁 Clic para abrir carpeta")
        if [ "$ACTION" = "default" ]; then
            thunar "$DOWNLOAD_DIR" &
        fi
    else
        # Extraer líneas de error relevantes (líneas que contienen ERROR: o últimas 3 líneas)
        ERR_MSG=$(echo "$OUTPUT" | grep -i "^ERROR:" | head -n 3)
        if [ -z "$ERR_MSG" ]; then
            ERR_MSG=$(echo "$OUTPUT" | tail -n 3)
        fi
        # Formatear y limitar longitud para una notificación clara
        ERR_MSG=$(echo "$ERR_MSG" | fold -s -w 80 | head -n 6)

        notify-send -a "yt-dlp" -r "$NOTIF_ID" -u critical -i dialog-error "yt-dlp" "❌ Error al descargar:\n$ERR_MSG"
    fi

    # Limpieza de miniatura temporal
    rm -f ${THUMB_PREFIX}* 2>/dev/null
) &
