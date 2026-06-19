# 🏠 Dotfiles

Configuraciones personales de desarrollo para macOS, gestionadas con [Tuckr](https://github.com/RaphGL/Tuckr).

## ⚡ Quick Start

```bash
# 1. Clonar repositorio
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles

# 2. Setup automático (recomendado para nueva Mac)
./scripts/quick-setup.sh

# O manualmente:

# 2a. Instalar Homebrew (si no está instalado)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2b. Instalar dependencias
brew bundle install

# 2c. Deploy configs con Tuckr (con hooks automáticos)
tuckr set Configs/*

# 2d. Verificar deployment
tuckr status
```

📖 **Para setup completo en nueva Mac:** Ver [SETUP.md](SETUP.md)  
🔧 **Documentación de hooks:** Ver [Hooks/README.md](Hooks/README.md)

## 📁 Estructura

```
.dotfiles/
├── Configs/           # Configuraciones organizadas por herramienta
│   ├── nvim/         # Neovim Pure (config principal)
│   │   └── nvim/     # Config principal minimalista
│   ├── tmux/         # Tmux + Tmuxinator
│   ├── zsh/          # Zsh configs, aliases, completions
│   ├── gitconfig/    # Git config + Delta themes
│   ├── iterm2/       # iTerm2 settings + temas generados
│   ├── lazygit/      # Lazygit configs por tema
│   ├── starship/     # Starship prompt
│   ├── karabiner/    # Karabiner key remapping
│   └── ...           # Otras herramientas
├── Hooks/             # Tuckr hooks (automatización)
│   ├── README.md     # Documentación de hooks
│   ├── global/       # Hooks que corren siempre
│   ├── iterm2/       # Configura iTerm2 automáticamente
│   ├── tmux/         # Instala TPM y plugins
│   ├── zsh/          # Instala plugins de Zsh
│   └── ...           # Más hooks por programa
├── scripts/          # Scripts de automatización
│   ├── theme-tools/  # Gestión de archivos de temas en git
│   ├── export-system-settings.sh
│   ├── export-iterm2-settings.sh
│   └── setup-iterm2-sync.sh
├── system-settings/  # Configuraciones exportadas de macOS
├── Brewfile          # Paquetes de Homebrew
├── SETUP.md          # Guía completa de setup
└── README.md         # Este archivo
```

- **Hook automático:** `Hooks/global/post.sh` aplica skip-worktree después de cada deploy

**Scripts manuales (si necesario)
Este dotfiles incluye sincronización automática de temas entre herramientas:

- **Neovim** controla el tema principal
- Cambia automáticamente: iTerm2, Lazygit, Starship, Delta, Tmux, btop, eza
- Archivos generados usan `git skip-worktree` para evitar ruido en commits

**Scripts:**
- `scripts/theme-tools/skip-theme-tracking.sh` - Ignorar cambios locales de temas
- `scripts/theme-tools/restore-theme-tracking.sh` - Restaurar tracking temporal

## 🛠️  Herramientas Principales

### Terminal & Shell
- **eza:** Modern `ls` replacement con colores
- **bat:** Modern `cat` con syntax highlighting  
- **delta:** Better git diff viewer
- **z:** Jump to directories by frecency
- **tmux + tmuxinator:** Terminal multiplexer + project manager
- **starship:** Fast, customizable prompt
### Development
- **Neovim:** Editor principal con configuración minimalista nativa
- **jdtls:** Java LSP server
- **fnm:** Fast Node Manager
- **pyenv:** Python version manager
- **jenv:** Java version manager

### Git
- **lazygit:** Terminal UI for git
- **gh:** GitHub CLI

### System
- **aerospace:** Tiling window manager para macOS
- **karabiner-elements:** Key remapping
- **btop:** Beautiful process monitor
- **ncdu:** Disk usage analyzer
- **neofetch:** System info display

### Containers
- **Docker Desktop + docker-compose**
- **Podman + podman-compose**
- **Lima:** Linux VMs

### File Management
- **yazi:** Terminal file manager con previews
- **fd:** Fast `find` alternative
- **ripgrep:** Fast `grep` alternative
- **fzf:** Fuzzy finder

Ver lista completa en [SETUP.md](SETUP.md)

## 📦 Gestión de Paquetes

### Homebrew

**Exportar paquetes actuales:**
```bash
brew bundle dump --force
```

**Instalar desde Brewfile:**
```bash
brew bundle install
```

**Cleanup:**
```bash
brew bundle cleanup --force  # Remove unlisted packages
```

## 🔧 Mantenimiento

### Exportar configuraciones actuales

```bash
# Exportar Brewfile
brew bundle dump --force

# Exportar system settings
./scripts/export-system-settings.sh

# Verificar/configurar iTerm2
./scripts/export-iterm2-settings.sh
```

### Gestionar archivos de temas

```bash
# Aplicar skip-worktree (ignorar cambios locales)
./scripts/theme-tools/skip-theme-tracking.sh

# Ver archivos con skip-worktree
git ls-files -v | grep '^S'

# Restaurar tracking (para commit)
./scripts/theme-tools/restore-theme-tracking.sh
```

## 🚀 Tuckr Usage

```bashtodo con automatización (recomendado)
tuckr set Configs/*

# Deploy específico con hooks
tuckr set nvim
tuckr set zsh tmux

# Deploy sin hooks (solo symlinks)
tuckr add Configs/*

# Deploy específico sin hooks
tuckr add Configs/nvim

# Remover config
tuckr rm Configs/nvim

# Estado
tuckr status
```

**📖 Hooks disponibles:** Ver [Hooks/README.md](Hooks/README.md)kr status
```

## Previous steps

### Prettier cat and git diff
1. install bat at [install](https://github.com/sharkdp/bat#installation)
2. install delta at [install](https://dandavison.github.io/delta/installation.html)

### Setting plugins zsh
Install fzf, fzf-tab, zsh-syntax-highlighting from [git](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)

### Install tools
* **eza:** colorls
* **z:** save index in cd
* **tmux:** terminal multiplexer
* **tmuxinator:** tmux project admin
* **aerospace:** macos tiling window manager
* **ghostty:** terminal emulator
* **jdtls:** for neovim java lsp
* **lazygit:** terminal git ui
* **lazydocker:** terminal docker gui
* **speedtest-cli:** internet speedtest
* **tldr:** command detail information
* **thefuck:** fix commands
* **ncdu:** storage cleaner
* **btop:** ui admin process
* **jadx:** java decompiler
* **clean-me:** uninstall apps and clean macos
* **daisydisk:** disk space admin
* **kanata:** remap keys macos
* **ttyper:** practice typing in console
* **zbar:** migrate 2nd factor qr from authenticator to keepass(keepassXC)
* **neofetch:** system info
* **axel:** download acelerator
* **yazi**: terminal file manager
* **mdfind**:alternative to locate (from spotlight / in system) 
* **locate**: index db of system files
* **sketchybar**: integrate with aerospace


> #### example of use zbar
> https://github.com/mchehab/zbar - read qr-code from google authenticator 
> zbarimg --raw ~/SCR-20250215-pfdn.png

> #### example of use axel
> axel -n 8 -a https://url

> #### example of use ffmpeg
> ffmpeg -i input.mp4 input.avi 

```sh
##unix tools
brew install --cask font-maple-mono font-maple-mono-nf
## After install tmuxinator set completions see zsh https://github.com/tmuxinator/tmuxinator
brew install eza z tmux ghostty jdtls lazygit lazydocker speedtest-cli tldr thefuck ncdu btop jadx zbar neofetch axel ffmpeg kanata httpie tmuxinator

cargo install ttyper
## locate => index db to find files in system

## yazi & dependencies
brew install yazi ffmpegthumbnailer sevenzip jq poppler fd ripgrep fzf zoxide imagemagick font-symbols-only-nerd-font
## install theme for yazi
ya pack -a yazi-rs/flavors:catppuccin-mocha

##macos tools
brew install clean-me daisydisk aerospace
```
