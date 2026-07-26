# Created by newuser for 5.9

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Created by newuser for 5.9

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias c='clear'
#alias ssh='ssh.exe'
#alias ssh-add='ssh-add.exe'
#alias vim='nvim'
alias p='pnpm'
# Reemplazos de ls con eza
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lla='eza -lah --icons --group-directories-first'
#alias sync='rsync -avh --progress /mnt/e ruben@192.168.1.26:/home/ruben/Files/'
# El "Alias de Árbol" (Tree view)
# Muestra carpetas, iconos y hasta 3 niveles de profundidad
alias lt='eza --tree --level=3 --icons --group-directories-first'

#Path
# 1. Definimos las rutas de usuario y herramientas primero
export JAVA_HOME="$HOME/.java/jdk/jdk-21.0.6+7"

# 2. Construimos el PATH de forma acumulativa (Sin borrar nada)
export PATH="$HOME/.local/bin:$HOME/.dotnet/tools:$JAVA_HOME/bin:$PATH"

# 3. Aseguramos las rutas base de Arch (opcional pero recomendado)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:$PATH"
export PATH=$PATH:/usr/local/go/bin
export PATH="$PATH:$(go env GOPATH)/bin"
#export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
#export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:$PATH
#export JAVA_HOME=$HOME/.java/jdk/jdk-21.0.6+7
#export PATH=$JAVA_HOME/bin:$PATH
#export PATH=$HOME/.local/bin:$PATH
#export PATH=~/.dotnet/tools
#export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl
#export GALLIUM_DRIVER=d3d12
#export LIBVA_DRIVER_NAME=d3d12

# Evitar que Mesa use dzn (Vulkan sobre D3D12) que falla en WSL

# Shell integrations
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init --cmd cd zsh)"

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

# bun completions & bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export LIBVIRT_DEFAULT_URI="qemu:///system"

export PATH="$HOME/.local/bin:$HOME/.dotnet/tools:$PATH"

