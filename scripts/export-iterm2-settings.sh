#!/bin/bash
# Script to export iTerm2 settings to dotfiles
# Run this after making changes to iTerm2 configuration you want to preserve

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ITERM2_DIR="$DOTFILES_ROOT/Configs/iterm2"

echo "🖥️  Exportando configuraciones de iTerm2..."

# Check if iTerm2 is installed
if ! defaults read com.googlecode.iterm2 &>/dev/null; then
    echo "⚠️  iTerm2 no está instalado o no tiene preferencias guardadas"
    exit 1
fi

# Check if iTerm2 uses custom preferences location
CUSTOM_FOLDER=$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null)
LOAD_PREFS=$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null)

if [[ "$LOAD_PREFS" == "1" ]] && [[ -n "$CUSTOM_FOLDER" ]]; then
    echo "  ℹ️  iTerm2 usa carpeta personalizada: $CUSTOM_FOLDER"
    echo "  → Verificando si ya está en dotfiles..."
    
    # Normalize paths for comparison
    CUSTOM_FOLDER_REAL=$(cd "$CUSTOM_FOLDER" 2>/dev/null && pwd)
    ITERM2_DIR_REAL=$(cd "$ITERM2_DIR" 2>/dev/null && pwd)
    
    if [[ "$CUSTOM_FOLDER_REAL" == "$ITERM2_DIR_REAL" ]]; then
        echo "  ✅ Las preferencias ya se guardan en dotfiles"
        echo "  → Ubicación: $ITERM2_DIR"
    else
        echo "  ⚠️  Las preferencias están en: $CUSTOM_FOLDER"
        echo "  → Para moverlas a dotfiles, ejecuta:"
        echo "     defaults write com.googlecode.iterm2 PrefsCustomFolder -string '$ITERM2_DIR'"
        echo "     defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true"
        echo "     # Luego reinicia iTerm2"
    fi
else
    echo "  ℹ️  iTerm2 usa preferencias del sistema (~/Library/Preferences)"
    echo "  → Para guardar en dotfiles, configura:"
    echo "     1. Abre iTerm2 → Preferences → General → Preferences"
    echo "     2. Marca 'Load preferences from a custom folder or URL'"
    echo "     3. Selecciona: $ITERM2_DIR"
    echo "     4. Marca 'Save changes to folder when iTerm2 quits'"
    echo ""
    echo "  Alternativamente, ejecuta:"
    echo "     defaults write com.googlecode.iterm2 PrefsCustomFolder -string '$ITERM2_DIR'"
    echo "     defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true"
    echo "     defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true"
    echo "     # Luego reinicia iTerm2"
fi

echo ""
echo "📝 Notas:"
echo "  - Los temas de colores generados están en: $ITERM2_DIR/generated/"
echo "  - Estos archivos están en skip-worktree para evitar ruido en git"
echo "  - Para agregar un nuevo tema manualmente, ponlo fuera de generated/"
