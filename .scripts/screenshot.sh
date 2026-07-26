#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

SELECTION=$(slurp 2>/dev/null)

if [ -n "$SELECTION" ]; then
    FILE="$DIR/captura_$(date +%Y-%m-%d_%H-%M-%S).png"
    grim -g "$SELECTION" - | tee "$FILE" | wl-copy --type image/png
    pw-play /usr/share/sounds/freedesktop/stereo/screen-capture.oga &
    notify-send -a "screenshot" -i "$FILE" "Captura guardada" "$FILE"
fi
