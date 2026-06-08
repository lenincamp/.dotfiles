#!/bin/bash
# Global post-hook: Applied theme tracking after any tuckr deployment
# This prevents theme-generated files from cluttering git history

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"

echo "🎨 Aplicando skip-worktree a archivos de temas..."

if [[ -f "$DOTFILES_ROOT/scripts/theme-tools/skip-theme-tracking.sh" ]]; then
    "$DOTFILES_ROOT/scripts/theme-tools/skip-theme-tracking.sh"
else
    echo "⚠️  Script skip-theme-tracking.sh no encontrado"
    echo "   Ejecuta manualmente: ~/.dotfiles/scripts/theme-tools/skip-theme-tracking.sh"
fi
