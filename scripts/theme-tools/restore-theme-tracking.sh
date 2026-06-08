#!/bin/bash
# Script to restore tracking of theme files (if you need to commit real changes)

DOTFILES_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$DOTFILES_ROOT"

echo "🔄 Restaurando tracking de archivos de temas..."

git ls-files -v | grep '^S' | cut -c3- | while read file; do
    git update-index --no-skip-worktree "$file"
    echo "  ✓ $file"
done

echo "✅ Tracking restaurado. Usa '$DOTFILES_ROOT/scripts/theme-tools/skip-theme-tracking.sh' para volver a ignorar."
