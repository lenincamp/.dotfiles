#!/bin/bash
# Script to stop tracking theme-generated files locally
# Files remain in repo as templates but local changes are ignored

DOTFILES_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$DOTFILES_ROOT"

echo "🎨 Configurando archivos de temas para ignorar cambios locales..."

# iTerm2 generated themes
git ls-files 'Configs/iterm2/generated/*.itermcolors' | while read file; do
    git update-index --skip-worktree "$file"
done

# Delta generated config
git update-index --skip-worktree 'Configs/gitconfig/delta-generated.gitconfig'

# Gemini settings
git update-index --skip-worktree 'Configs/gemini/.gemini/settings.json'

# Lazygit generated configs
git ls-files 'Configs/lazygit/Library/Application Support/lazygit/config-generated-*.yml' | while read file; do
    git update-index --skip-worktree "$file"
done

# Starship config
git update-index --skip-worktree 'Configs/starship/.config/starship.toml'

echo "✅ Archivos configurados. Para ver la lista:"
echo "   git ls-files -v | grep '^S'"
echo ""
echo "Para revertir (si necesitas commitear cambios reales):"
echo "   $DOTFILES_ROOT/scripts/theme-tools/restore-theme-tracking.sh"
