#!/bin/bash
# iTerm2 pre-hook: Configure iTerm2 to save preferences in dotfiles

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
ITERM2_DIR="$DOTFILES_ROOT/Configs/iterm2"

echo "🖥️  Configurando iTerm2 para usar dotfiles..."

# Check if iTerm2 is installed
if ! defaults read com.googlecode.iterm2 &>/dev/null; then
    echo "⚠️  iTerm2 no está instalado, saltando configuración"
    exit 0
fi

# Check current settings
CUSTOM_FOLDER=$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null)
LOAD_PREFS=$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null)

# Normalize paths
CUSTOM_FOLDER_REAL=$(cd "$CUSTOM_FOLDER" 2>/dev/null && pwd)
ITERM2_DIR_REAL=$(cd "$ITERM2_DIR" 2>/dev/null && pwd)

# Only configure if not already set
if [[ "$LOAD_PREFS" != "1" ]] || [[ "$CUSTOM_FOLDER_REAL" != "$ITERM2_DIR_REAL" ]]; then
    echo "  → Configurando ubicación de preferencias..."
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM2_DIR"
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
    defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true
    
    echo "  ✅ Configuración aplicada"
    echo "  ⚠️  Reinicia iTerm2 para que tome efecto"
else
    echo "  ✅ iTerm2 ya está configurado correctamente"
fi
