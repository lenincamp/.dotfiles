# Tuckr Hooks

Hooks automatizan tareas de configuración antes y después de deployar dotfiles.

## 📋 Estructura

```
Hooks/
├── global/          # Se ejecuta para todos los deployments
│   └── post.sh      # Aplica skip-worktree a archivos de temas
├── aerospace/
│   └── post.sh      # Inicia Aerospace
├── iterm2/
│   └── pre.sh       # Configura iTerm2 para usar dotfiles
├── nvim/
│   └── post.sh      # Verifica dependencias de Neovim
├── sketchybar/
│   ├── pre.sh       # Instala sketchybar
│   └── post.sh      # Copia configs y inicia servicio
├── tmux/
│   └── post.sh      # Instala TPM y plugins
└── zsh/
    └── post.sh      # Instala plugins de Zsh
```

## 🚀 Uso

### Deploy todo con hooks
```bash
tuckr set *
```

### Deploy específico con hooks
```bash
tuckr set nvim
tuckr set zsh tmux
```

### Deploy sin ejecutar hooks
```bash
tuckr add *          # Solo symlinks, sin hooks
```

## 📝 Tipos de Hooks

### `pre.sh`
Se ejecuta **antes** de crear los symlinks. Útil para:
- Instalar dependencias
- Crear directorios necesarios
- Configurar preferencias del sistema

### `post.sh`
Se ejecuta **después** de crear los symlinks. Útil para:
- Instalar plugins
- Compilar assets
- Iniciar servicios
- Verificar configuración

## 🔧 Hooks Disponibles

### `global/post.sh`
**Automático:** Aplica `skip-worktree` a archivos de temas después de cualquier deploy.

### `iterm2/pre.sh`
Configura iTerm2 para guardar preferencias en `Configs/iterm2/` automáticamente.

### `tmux/post.sh`
- Clona TPM (Tmux Plugin Manager)
- Instala plugins si tmux está corriendo

### `zsh/post.sh`
Instala plugins de Zsh:
- fzf-tab
- zsh-syntax-highlighting
- zsh-autosuggestions

### `nvim/post.sh`
Verifica dependencias de Neovim (bob, tree-sitter CLI)

### `aerospace/post.sh`
Inicia Aerospace si no está corriendo

### `sketchybar/pre.sh + post.sh`
Instala, configura e inicia Sketchybar

## 🆕 Crear Nuevos Hooks

1. **Crear directorio:**
   ```bash
   mkdir -p Hooks/<nombre_programa>
   ```

2. **Crear hook:**
   ```bash
   # Pre-hook (antes de symlinks)
   touch Hooks/<nombre_programa>/pre.sh
   
   # Post-hook (después de symlinks)
   touch Hooks/<nombre_programa>/post.sh
   ```

3. **Hacer ejecutable:**
   ```bash
   chmod +x Hooks/<nombre_programa>/*.sh
   ```

4. **Ejemplo de template:**
   ```bash
   #!/bin/bash
   echo "🔧 Configurando <programa>..."
   
   # Tu código aquí
   
   echo "✅ <programa> configurado"
   ```

## 💡 Variables Útiles

```bash
# Ruta a dotfiles (fallback a ~/.dotfiles)
DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"

# Directorio de configs específico
CONFIG_DIR="$DOTFILES_ROOT/Configs/<programa>"

# Home del usuario
HOME="$HOME"
```

## ⚠️  Consideraciones

- **Idempotencia:** Los hooks deben poder ejecutarse múltiples veces sin problemas
- **Verificar dependencias:** Usa `command -v` para verificar si un comando existe
- **Mensajes claros:** Usa emojis y mensajes descriptivos para feedback
- **Exit codes:** Retorna 0 en éxito, no-zero en error
- **Documentar:** Comenta qué hace cada hook al inicio del archivo

## 🔍 Debug

Ver qué hooks se ejecutan:
```bash
# Dry run (si Tuckr lo soporta)
tuckr set --dry-run <programa>

# Ver output detallado
tuckr set <programa> 2>&1 | tee hook-output.log
```

Verificar permisos:
```bash
ls -l Hooks/*/*.sh
```

## 📚 Referencias

- [Documentación oficial de Tuckr](https://raphgl.github.io/Tuckr/)
- [Ejemplos de hooks](https://github.com/RaphGL/Tuckr/tree/master/book/src)
