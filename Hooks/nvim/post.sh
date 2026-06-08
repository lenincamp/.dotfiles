#!/bin/bash
# Nvim post-hook: Setup Neovim dependencies

echo "📝 Configurando Neovim..."

# Install bob (Neovim version manager) if not exists
if ! command -v bob &>/dev/null; then
    echo "  → bob no está instalado"
    echo "  → Instala bob: cargo install bob-nvim"
else
    echo "  ✅ bob está instalado"
fi

# Install treesitter CLI if not exists
if ! command -v tree-sitter &>/dev/null; then
    echo "  → tree-sitter CLI no está instalado"
    echo "  → Instala: npm install -g tree-sitter-cli"
else
    echo "  ✅ tree-sitter CLI está instalado"
fi

echo "  ℹ️  Abre Neovim para instalar plugins (lazy.nvim los instalará automáticamente)"
