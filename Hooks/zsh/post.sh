#!/bin/bash
# Zsh post-hook: Setup zsh plugins and completions

echo "🐚 Configurando Zsh..."

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install fzf-tab if not exists
if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
    echo "  → Instalando fzf-tab..."
    git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
fi

# Install zsh-syntax-highlighting if not exists
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    echo "  → Instalando zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Install zsh-autosuggestions if not exists
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    echo "  → Instalando zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

echo "  ✅ Plugins de Zsh configurados"
echo "  ℹ️  Reinicia tu shell para aplicar cambios"
