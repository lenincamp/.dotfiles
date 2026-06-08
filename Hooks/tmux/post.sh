#!/bin/bash
# Tmux post-hook: Install TPM (Tmux Plugin Manager) and plugins

echo "📦 Configurando Tmux Plugin Manager..."

TPM_DIR="$HOME/.tmux/plugins/tpm"

# Clone TPM if not exists
if [[ ! -d "$TPM_DIR" ]]; then
    echo "  → Clonando TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "  ✅ TPM instalado"
else
    echo "  ✅ TPM ya está instalado"
fi

# Install plugins if tmux is running
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
    echo "  → Instalando plugins de tmux..."
    "$TPM_DIR/bin/install_plugins"
    echo "  ✅ Plugins instalados"
else
    echo "  ℹ️  Inicia tmux y presiona 'prefix + I' para instalar plugins"
fi
