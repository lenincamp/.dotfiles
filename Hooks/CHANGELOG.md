# Tuckr Hooks - Changelog

## Hooks Creados

### 🌐 Global
- **`global/post.sh`**: Aplica skip-worktree automáticamente después de cualquier deployment
  - Ejecuta `scripts/theme-tools/skip-theme-tracking.sh`
  - Previene ruido en git de archivos de temas generados

### 🖥️  iTerm2
- **`iterm2/pre.sh`**: Configura iTerm2 para guardar preferencias en dotfiles
  - Configura `PrefsCustomFolder` → `Configs/iterm2/`
  - Habilita `LoadPrefsFromCustomFolder`
  - Idempotente: detecta si ya está configurado

### 📦 Tmux
- **`tmux/post.sh`**: Setup de Tmux Plugin Manager
  - Clona TPM si no existe
  - Instala plugins automáticamente si tmux está corriendo
  - Proporciona instrucciones si tmux no está activo

### 🐚 Zsh
- **`zsh/post.sh`**: Instala plugins de Zsh
  - fzf-tab
  - zsh-syntax-highlighting
  - zsh-autosuggestions
  - Detecta si ya están instalados

### 📝 Neovim
- **`nvim/post.sh`**: Verifica dependencias de Neovim
  - Verifica bob (version manager)
  - Verifica tree-sitter CLI
  - Proporciona instrucciones de instalación

### 🚀 Aerospace
- **`aerospace/post.sh`**: Inicia Aerospace window manager
  - Detecta si ya está corriendo
  - Inicia automáticamente si está instalado
  - Proporciona instrucciones para auto-start en login

### 🎨 Sketchybar
- **`sketchybar/pre.sh`**: Instala Sketchybar (existente)
- **`sketchybar/post.sh`**: Copia configs e inicia servicio (existente)

## Automatización Lograda

### Antes (Manual)
```bash
# 1. Deploy dotfiles
tuckr add Configs/*

# 2. Configurar skip-worktree manualmente
./scripts/theme-tools/skip-theme-tracking.sh

# 3. Configurar iTerm2 manualmente
./scripts/setup-iterm2-sync.sh

# 4. Instalar TPM manualmente
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 5. Instalar plugins de Zsh manualmente
# ... (muchos pasos)

# 6. Reiniciar servicios manualmente
# ...
```

### Ahora (Automático)
```bash
# TODO en un comando
tuckr set Configs/*

# O setup completo en nueva Mac
./scripts/quick-setup.sh
```

## Beneficios

✅ **Idempotencia**: Los hooks pueden ejecutarse múltiples veces sin problemas  
✅ **Feedback claro**: Mensajes con emojis para cada paso  
✅ **Verificación**: Detectan si dependencias ya están instaladas  
✅ **Graceful degradation**: Continúan si algo falta, no fallan  
✅ **Documentación**: Cada hook documenta qué hace y por qué  

## Uso

### Setup inicial
```bash
tuckr set Configs/*
```

### Agregar nuevo programa con hooks
```bash
tuckr set <programa>
```

### Deploy sin hooks (solo symlinks)
```bash
tuckr add Configs/*
```

## Próximos Hooks Sugeridos

- **`gitconfig/post.sh`**: Configurar nombre/email de git si no están set
- **`karabiner/post.sh`**: Reiniciar karabiner después de cambios
- **`yazi/post.sh`**: Instalar flavors/plugins de yazi
- **`ghostty/post.sh`**: Compilar shaders si usa GPU acceleration

## Referencias

- Documentación: [Hooks/README.md](README.md)
- Tuckr docs: https://raphgl.github.io/Tuckr/
