#!/bin/bash
# Script to set up iTerm2 to automatically save preferences to dotfiles

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ITERM2_DIR="$DOTFILES_ROOT/Configs/iterm2"

echo "🔧 Configurando iTerm2 para guardar preferencias en dotfiles..."

# Create directory if it doesn't exist
mkdir -p "$ITERM2_DIR"

# Configure iTerm2 to use custom preferences folder
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM2_DIR"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true

echo "✅ Configuración aplicada"
echo ""
echo "📌 Próximos pasos:"
echo "  1. Reinicia iTerm2 para que tome los cambios"
echo "  2. iTerm2 cargará las preferencias desde: $ITERM2_DIR"
echo "  3. Todos los cambios futuros se guardarán automáticamente ahí"
echo ""
echo "⚠️  IMPORTANTE:"
echo "  Si ya tenías preferencias personalizadas, iTerm2 las reemplazará"
echo "  con las que están en dotfiles. Haz backup si es necesario."
