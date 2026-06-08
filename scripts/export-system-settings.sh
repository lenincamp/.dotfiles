#!/bin/bash
# Script to export macOS system settings and preferences
# Run this script periodically to capture system configuration changes

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS_DIR="$DOTFILES_ROOT/system-settings"

echo "🔧 Exportando configuraciones del sistema macOS..."

# Create settings directory structure
mkdir -p "$SETTINGS_DIR/defaults"
mkdir -p "$SETTINGS_DIR/LaunchAgents"

# Export Dock settings
echo "  → Dock preferences"
defaults read com.apple.dock > "$SETTINGS_DIR/defaults/dock.plist" 2>/dev/null || echo "# No dock preferences found" > "$SETTINGS_DIR/defaults/dock.plist"

# Export Finder settings
echo "  → Finder preferences"
defaults read com.apple.finder > "$SETTINGS_DIR/defaults/finder.plist" 2>/dev/null || echo "# No finder preferences found" > "$SETTINGS_DIR/defaults/finder.plist"

# Export global preferences
echo "  → Global preferences"
defaults read NSGlobalDomain > "$SETTINGS_DIR/defaults/global.plist" 2>/dev/null || echo "# No global preferences found" > "$SETTINGS_DIR/defaults/global.plist"

# Export Trackpad settings
echo "  → Trackpad preferences"
defaults read com.apple.AppleMultitouchTrackpad > "$SETTINGS_DIR/defaults/trackpad.plist" 2>/dev/null || echo "# No trackpad preferences found" > "$SETTINGS_DIR/defaults/trackpad.plist"

# Export Keyboard settings
echo "  → Keyboard preferences"
defaults read com.apple.keyboard > "$SETTINGS_DIR/defaults/keyboard.plist" 2>/dev/null || echo "# No keyboard preferences found" > "$SETTINGS_DIR/defaults/keyboard.plist"

# Create a human-readable summary
echo "  → Generando resumen legible"
cat > "$SETTINGS_DIR/README.md" << 'EOF'
# macOS System Settings

Este directorio contiene las configuraciones exportadas del sistema macOS.

## Archivos

- `defaults/` - Preferencias exportadas con `defaults read`
- `LaunchAgents/` - Agentes de usuario personalizados
- `restore-settings.sh` - Script para restaurar configuraciones (⚠️ usar con precaución)

## Uso

### Exportar configuraciones actuales
```bash
./scripts/export-system-settings.sh
```

### Ver diferencias
```bash
git diff system-settings/
```

## ⚠️ Advertencias

- **NO** ejecutar `restore-settings.sh` ciegamente en un sistema nuevo
- Revisar cada archivo antes de aplicar
- Algunas configuraciones pueden ser específicas del hardware
- Algunas preferencias pueden requerir reiniciar el sistema o logout/login

## Configuraciones importantes

### Dock
- Tamaño, posición, auto-hide
- Apps favoritas (se almacenan como referencias de archivo)

### Finder
- Vista por defecto, extensiones de archivo
- Carpetas en sidebar

### Global
- Teclado, trackpad, mouse
- Apariencia (modo oscuro/claro)
- Idioma y región
EOF

echo "✅ Configuraciones exportadas en: $SETTINGS_DIR"
echo "   Revisa los cambios con: git diff system-settings/"
