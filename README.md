# Dotfiles Bootstrap & Symlink Installer

Este repositorio contiene la configuración personal de dotfiles y un script de instalación automatizada para Arch Linux. Instala dependencias de usuario, el entorno gráfico (Sway, Waybar, Mako, Rofi, Foot), herramientas de desarrollo, AUR helper (`yay`), aplicaciones web, y configura la shell por defecto a Zsh.

---

## ⚡ Novedades y Características Principales

- 🎹 **Configuración Adaptativa de Teclado (Laptop vs PC)**:
  - **Laptop** (layout `latam`).
  - **PC** (layout `us`).
  - Permite pasar opciones CLI (`--laptop`, `--pc`, `--keyboard <layout>`), seleccionar interactivamente o auto-detectar por hardware (`/sys/class/dmi/id/chassis_type`).
  - Escribe en un archivo local no rastreado por git (`~/.config/sway/config.d/99-keyboard-local.conf`), manteniendo el repositorio 100% limpio.
- 🛡️ **Respaldos Automáticos sin Pérdida de Datos**:
  - Si un archivo o directorio real existe en el destino (y no es un symlink), el script crea un respaldo automático con timestamp (`.bak.<timestamp>`) antes de crear el enlace.
- 📦 **Instalación Completa de Paquetes en Arch Linux**:
  - **Pacman**: Base, Zsh, Sway, Swaybg, Waybar, Mako, Rofi, Foot, Grim, Slurp, Wl-clipboard, Thunar, Tumbler, Ffmpegthumbnailer, Polkit-gnome, Xdg-desktop-portals (Wayland/GTK/WLR), Xwayland, Playerctl, Brightnessctl, Wireplumber, MPV, Yt-dlp, Ristretto, y fuentes (Noto & Emoji).
  - **AUR (`yay`)**: Si `yay` no está instalado, se compila e instala automáticamente para luego proveer Microsoft Edge, Visual Studio Code y Zen Browser.
- 💻 **Entorno Específico para PC (`.zprofile`)**:
  - `.zprofile` incluye variables de entorno dedicadas para GPUs NVIDIA y Wayland. Se enlaza **únicamente en la PC** (`--pc`) y se omite/remueve en laptops con gráficos AMD.
- 🔒 **Modo Seguro Sudo / Root**:
  - Tolerancia para ejecutar como usuario normal con `sudo` o como `root` en chroot (omite la compilación de `yay` si no existe un usuario no-root resoluble).

---

## 🚀 Uso

```bash
chmod +x install.sh

# Opción 1: Selección automática o interactiva
./install.sh

# Opción 2: Especificando el perfil de Laptop (Teclado latam)
./install.sh --laptop

# Opción 3: Especificando el perfil de PC (Teclado US + .zprofile con Nvidia)
./install.sh --pc
```

### Probar sin modificar el entorno del usuario:

```bash
DOTFILES_HOME=/tmp/dotfiles-home ./install.sh --laptop
```

---

## 📂 Estructura del Repositorio

- **Archivos del Home**: `.bashrc`, `.gitconfig`, `.p10k.zsh`, `.zshrc`, `.zprofile` (específico PC)
- **Configuraciones XDG (`.config/`)**:
  - `sway/`: Configuración modular de Sway, wallpaper (`wallpaper/joyboy.png`) y `config.d/`
  - `waybar/`, `mako/`, `rofi/`, `foot/`, `hypr/`, `Thunar/`
- **Scripts y Fuentes**: `.scripts/` (incluyendo `screenshot.sh`), `.local/share/fonts/`