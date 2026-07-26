#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# notifications.sh — Menú de notificaciones Rofi en tema Gruvbox
# Consume `notification-client history -f json` con miniaturas a la izquierda
# ─────────────────────────────────────────────────────────────────────────────

THEME="$HOME/.config/rofi/themes/notifications.rasi"
ICON_FALLBACK="$HOME/.config/rofi/themes/icons/notification.svg"

# Verificar dependencias
if ! command -v notification-client &>/dev/null; then
    notify-send -u critical "Rofi Notificaciones" "Error: notification-client no está instalado"
    exit 1
fi

# Generar formato dmenu enviando directamente a STDOUT en 1 SOLA LÍNEA por notificación
fetch_notifications() {
    python3 - "$ICON_FALLBACK" << 'EOF'
import sys, json, subprocess, os, html

fallback_icon = sys.argv[1]

try:
    raw = subprocess.check_output(['notification-client', 'history', '-f', 'json'])
    data = json.loads(raw)
except Exception:
    data = []

if not data:
    sys.exit(0)

for item in data:
    nid = item.get('id', '')
    app = html.escape(str(item.get('app_name') or 'Notificación'))
    summary = html.escape(str(item.get('summary') or ''))
    body = html.escape(str(item.get('body') or ''))
    created = item.get('created_at', '')
    urgency_val = item.get('urgency', 1)
    category = html.escape(str(item.get('category') or ''))
    
    # Mapear nivel de urgencia
    urgency_map = {0: 'baja', 1: 'normal', 2: 'crítica'}
    urgency_str = urgency_map.get(urgency_val, '')
    
    # Extraer hora HH:MM y fecha YYYY-MM-DD
    time_str = ""
    date_str = ""
    if created and len(created) >= 16:
        time_str = created[11:16]
        date_str = created[:10]
    
    # Determinar miniatura/ícono
    img_path = item.get('image_path') or ''
    app_icon = item.get('app_icon') or ''
    
    icon_to_use = fallback_icon
    if img_path and os.path.exists(img_path):
        icon_to_use = img_path
    elif app_icon and os.path.exists(app_icon):
        icon_to_use = app_icon
    elif app_icon:
        icon_to_use = app_icon
        
    # Limpiar el cuerpo: reemplaza saltos de línea por espacios para garantizar 1 sola línea
    clean_body = body.replace('\r', ' ').replace('\n', ' ').strip()
    if len(clean_body) > 140:
        clean_body = clean_body[:137] + '...'
        
    # Construir texto principal con Pango Markup
    parts = []
    if time_str:
        parts.append(f'<span foreground="#fe8019">[{html.escape(time_str)}]</span>')
    parts.append(f'<span foreground="#fabd2f"><b>{app}</b></span>')
    
    if summary:
        parts.append(f'<span foreground="#ebdbb2"><b>— {summary}</b></span>')
        
    if clean_body and clean_body != summary:
        sep = "— " if summary else ""
        parts.append(f'<span foreground="#a89984">{sep}{clean_body}</span>')
        
    # Metadatos secundarios indexables por el buscador de Rofi (Fecha, Urgencia, Categoría, #ID)
    meta_tags = []
    if date_str:
        meta_tags.append(date_str)
    if urgency_str:
        meta_tags.append(f'urgencia:{urgency_str}')
    if category:
        meta_tags.append(f'cat:{category}')
    if nid:
        meta_tags.append(f'#{nid}')
        
    if meta_tags:
        meta_str = html.escape(" ".join(meta_tags))
        parts.append(f'<span foreground="#7c6f64" size="x-small">[{meta_str}]</span>')
        
    display_str = " ".join(parts)
    
    # Ruta de archivo si existe (para abrir capturas de pantalla)
    file_path = img_path if (img_path and os.path.exists(img_path)) else (body if os.path.exists(body) else '')
    info_meta = f"{nid}|{file_path}"
    
    # Escribir a stdout en formato rofi dmenu: <texto>\0icon\x1f<icon>\x1finfo\x1f<meta>\n
    sys.stdout.write(f"{display_str}\x00icon\x1f{icon_to_use}\x1finfo\x1f{info_meta}\n")
    sys.stdout.flush()
EOF
}

# Pipe directo a rofi con búsqueda tokenizada (-tokenize)
ROFI_OUT=$(fetch_notifications | rofi \
    -dmenu \
    -theme              "$THEME" \
    -p                  "󰂚 Historial" \
    -mesg               "<b>[Enter]</b> Abrir/Leído  |  <b>[Alt+C]</b> Borrar historial" \
    -markup-rows \
    -show-icons \
    -tokenize \
    -format             "info" \
    -kb-custom-1        "Alt+c" \
    -hover-select \
    -me-select-entry     "" \
    -me-accept-entry     "MousePrimary")

EXIT_CODE=$?

# Acciones según la respuesta de Rofi
if [ $EXIT_CODE -eq 10 ]; then
    # Alt+C: Limpiar historial
    notification-client clear
    notify-send -i "$ICON_FALLBACK" "Notificaciones" "Se ha limpiado el historial de notificaciones."
    exit 0
elif [ $EXIT_CODE -eq 0 ] && [ -n "$ROFI_OUT" ]; then
    # Enter: Marcar como leída y abrir adjunto si existe
    IFS='|' read -r NID FILE_PATH <<< "$ROFI_OUT"

    if [ -n "$NID" ]; then
        notification-client read "$NID" &>/dev/null
    fi

    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        xdg-open "$FILE_PATH" &>/dev/null &
    fi
fi


