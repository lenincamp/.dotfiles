#!/bin/bash
# Quick maintenance script - Run this periodically to keep dotfiles up to date

DOTFILES_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_ROOT"

echo "🔄 Actualizando dotfiles..."
echo ""

# 1. Export Brewfile
echo "📦 Exportando Brewfile..."
brew bundle dump --force
echo "  ✅ Brewfile actualizado"
echo ""

# 2. Export system settings
echo "⚙️  Exportando configuraciones del sistema..."
./scripts/export-system-settings.sh
echo ""

# 3. Check iTerm2
echo "🖥️  Verificando iTerm2..."
./scripts/export-iterm2-settings.sh
echo ""

# 4. Show git status
echo "📊 Estado de git:"
git status --short
echo ""

echo "✅ Actualización completada!"
echo ""
echo "📝 Próximos pasos:"
echo "  1. Revisa los cambios: git diff"
echo "  2. Commit cambios importantes: git add <files> && git commit"
echo "  3. Push a remote: git push"
