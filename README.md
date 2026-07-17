# Dotfiles Bootstrap & Symlink Installer

Este repositorio incluye un bootstrap para Arch Linux que instala paquetes base, fzf y zoxide, cambia la shell a zsh y luego crea los enlaces simbólicos de la configuración.

## Uso

```bash
chmod +x install.sh
./install.sh
```

La fase de bootstrap está pensada para Arch Linux. Después de instalar las herramientas base, el script deja tus symlinks de dotfiles en su lugar.

Si quieres probarlo sin tocar tu home real, puedes usar:

```bash
DOTFILES_HOME=/tmp/dotfiles-home ./install.sh
```

El script enlaza archivos del home como `.zshrc`, `.bashrc`, `.gitconfig` y `.p10k.zsh`, y también las carpetas XDG que corresponden a `.config` y `.local/share`.

## Qué hace si ya existe algo

Si el destino ya existe, el instalador lo reemplaza por el enlace simbólico apuntando al archivo o carpeta del repositorio.

## Estructura esperada

- Archivos del home: `.bashrc`, `.gitconfig`, `.p10k.zsh`, `.zshrc`
- Configuración XDG: `.config/foot`, `.config/hypr`, `.config/rofi`, `.config/sway`, `.config/Thunar`, `.config/waybar`
- Recursos compartidos: `.local/share/fonts`

## Nota

La parte de bootstrap está pensada para Arch Linux; la parte de symlinks sigue aplicando a la estructura del repo.