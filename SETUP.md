# macOS System Customization

Este documento lista las aplicaciones, utilidades y configuraciones del sistema macOS que están instaladas y configuradas en esta máquina.

## 📦 Package Managers

### Homebrew
El `Brewfile` en la raíz del repositorio contiene todas las fórmulas, casks y taps instalados.

**Restaurar en una nueva Mac:**
```bash
cd ~/.dotfiles
brew bundle install
```

**Actualizar el Brewfile:**
```bash
brew bundle dump --force
```

## 🎨 Gestión de Temas

Este setup incluye sincronización automática de temas entre múltiples herramientas:

- **Neovim** → Controlador principal de temas
- **iTerm2** → Temas generados automáticamente en `Configs/iterm2/generated/`
- **Lazygit** → Configs generados en `Configs/lazygit/Library/Application Support/lazygit/`
- **Starship** → `Configs/starship/.config/starship.toml`
- **Delta (git diff)** → `Configs/gitconfig/delta-generated.gitconfig`
- **Tmux** → Integración con Catppuccin
- **btop** → `Configs/btop/.config/btop/btop.conf`
- **eza** → `Configs/eza/.config/eza/theme.yml`

Los archivos generados automáticamente usan `git update-index --skip-worktree` para evitar ruido en el historial de git.

Ver: `scripts/theme-tools/skip-theme-tracking.sh`

## 🖥️  Terminal & Shell

- **Terminal**: iTerm2
- **Shell**: Zsh con configuración personalizada
- **Prompt**: Starship
- **Multiplexer**: tmux con tmuxinator
- **Font**: Monaco Nerd Font (instalada vía Homebrew)

## ⌨️  Keyboard & Input

- **Karabiner-Elements**: Remapping de teclas (config en `Configs/karabiner/`)
- **Kanata**: Alternative keyboard remapper
- **Aerospace**: Window manager (config en `Configs/aerospace/`)

## 🛠️  Aplicaciones de Desarrollo

### Java
- **Versiones**: OpenJDK 11 y 21 (gestionadas con jenv)
- **Build Tools**: Maven, Gradle
- **IDE Config**: IntelliJ IDEA settings en `Configs/idea/`

### Node.js
- **Version Manager**: fnm (Fast Node Manager)

### Python
- **Version Manager**: pyenv

### Containers
- **Docker**: Docker Desktop + docker-compose
- **Podman**: Alternative a Docker + podman-compose
- **Lima**: Linux virtual machines

### Editors
- **Neovim**: Configuraciones en `Configs/nvim/`
   - `nvim/`: Config minimalista nativa - Sin frameworks, configuración manual
- **VS Code**: Settings sincronizadas vía Settings Sync

## 📊 System Monitoring

- **btop**: Monitor de recursos del sistema
- **htop**: Alternative process viewer
- **ncdu**: Disk usage analyzer
- **lnav**: Log file navigator

## 🔍 CLI Tools

### File Management
- **eza**: Modern replacement para `ls`
- **fd**: Modern replacement para `find`
- **bat**: Modern replacement para `cat`
- **ripgrep (rg)**: Fast grep alternative
- **fzf**: Fuzzy finder

### Git
- **lazygit**: TUI para git
- **lazydocker**: TUI para Docker
- **gh**: GitHub CLI
- **git-delta**: Better git diff viewer

### Other
- **atuin**: Shell history sync
- **tealdeer (tldr)**: Simplified man pages
- **thefuck**: Autocorrector de comandos
- **grc**: Generic colorizer
- **neofetch**: System info display

## 🎯 Productivity Apps

- **Alfred**: Application launcher (workflows en `alfred-workflows/`)
- **Raycast**: Modern launcher alternative

## 🌐 Cloud & DevOps

- **Azure CLI**: Azure command-line interface
- **kubectl**: Kubernetes CLI
- **kubectx**: Kubernetes context switcher
- **Spring CLI**: Spring Boot tools

## 🎨 Graphics & Media

- **ImageMagick**: Image manipulation
- **FFmpeg**: Video/audio processing (via ffmpegthumbnailer)

## 📲 iOS Development

- **ios-deploy**: Deploy apps to iOS devices

## 🔐 Security & Network

- **ngrok**: Tunneling tool
- **socat**: Socket utility
- **OpenSSL**: Multiple versions (1.1, 3)

## 📝 Documentación de Programas Instalados Manualmente

### Aplicaciones fuera de Homebrew

Lista las aplicaciones que instalaste desde la App Store, sitios web, o DMGs:

**App Store (usar `mas list` para ver):**
```bash
mas list
```

**Otras aplicaciones:**
- [ ] Figma
- [ ] Discord
- [ ] Slack
- [ ] Notion
- [ ] _Agregar otras aplicaciones aquí_

### Extensiones del Sistema

- **Karabiner-Elements**: _Versión y configuraciones especiales_
- **_Otras extensiones_**

## 🔄 Scripts de Mantenimiento

### Actualizar todas las configuraciones
```bash
# Exportar Brewfile
cd ~/.dotfiles
brew bundle dump --force

# Exportar configuraciones del sistema
./scripts/export-system-settings.sh

# Exportar configuraciones de iTerm2
./scripts/export-iterm2-settings.sh
```

### Configurar skip-worktree para archivos de temas
```bash
./scripts/theme-tools/skip-theme-tracking.sh
```

## ⚡ Quick Start

```bash
# Opción 1: Setup automático (RECOMENDADO)
cd ~/.dotfiles
./scripts/quick-setup.sh

# Opción 2: Manual (ver pasos detallados abajo)
```

## 🆕 Setup en una Nueva Mac (Detallado)

1. **Instalar Homebrew:**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Clonar dotfiles:**
   ```bash
   git clone <tu-repo> ~/.dotfiles
   cd ~/.dotfiles
   ```

3. **Instalar Tuckr:**
   ```bash
   cargo install tuckr
   # O via Homebrew si está disponible
   ```

4. **Instalar paquetes:**
   ```bash
   brew bundle install
   ```

5. **Deploy dotfiles con Tuckr:**
   ```bash
   # Deploy con hooks automáticos (recomendado)
   tuckr set Configs/*

   # O sin hooks (solo symlinks)
   tuckr add Configs/*
   ```

6. **Verificar deployment:**
   ```bash
   tuckr status
   ```

7. **Configurar iTerm2 sync:**
   ```bash
   ./scripts/setup-iterm2-sync.sh
   # Luego reiniciar iTerm2
   ```

8. **Aplicar configuraciones del sistema:**
   ```bash
   ./scripts/export-system-settings.sh
   ```

9. **Configurar skip-worktree:**
   ```bash
   ./scripts/theme-tools/skip-theme-tracking.sh
   ```

10. **(Opcional) Hooks adicionales:**
    - Verificar hooks disponibles: `cat Hooks/README.md`
    - Instalar TPM y plugins de Tmux
    - Instalar plugins de Zsh

## 🎯 Workflow Diario

### Deploy nuevo programa
```bash
# Con hooks (recomendado)
tuckr set <programa>

# Sin hooks (solo symlinks)
tuckr add <programa>
```

### Actualizar configuraciones
```bash
# Exportar todo
./scripts/update-dotfiles.sh

# O individualmente
brew bundle dump --force
./scripts/export-system-settings.sh
./scripts/export-iterm2-settings.sh
```

### Ver hooks disponibles
```bash
cat Hooks/README.md
ls -la Hooks/*/
```

## 📚 Referencias

- [Tuckr Documentation](https://github.com/RaphGL/Tuckr)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
