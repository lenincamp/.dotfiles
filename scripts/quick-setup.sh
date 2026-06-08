#!/bin/bash
# Quick setup script for new Mac
# Run this after cloning dotfiles

set -e

echo "🚀 Configuración rápida de dotfiles en nueva Mac"
echo ""

# 1. Check if in dotfiles directory
if [[ ! -f "Brewfile" ]]; then
    echo "❌ Error: Ejecuta este script desde el directorio .dotfiles"
    exit 1
fi

DOTFILES_ROOT="$(pwd)"
export DOTFILES_ROOT

# 2. Check Homebrew
echo "📦 Verificando Homebrew..."
if ! command -v brew &>/dev/null; then
    echo "  → Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "  ✅ Homebrew ya está instalado"
fi

# 3. Install packages from Brewfile
echo ""
echo "📦 Instalando paquetes desde Brewfile..."
read -p "¿Instalar todos los paquetes? (puede tardar un rato) [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew bundle install
else
    echo "  ⏭️  Saltando instalación de paquetes"
    echo "     Ejecuta manualmente: brew bundle install"
fi

# 4. Install Tuckr if not present
echo ""
echo "🔧 Verificando Tuckr..."
if ! command -v tuckr &>/dev/null; then
    echo "  → Instalando Tuckr..."
    cargo install tuckr
    
    # Add cargo bin to PATH if needed
    if [[ -d "$HOME/.cargo/bin" ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
else
    echo "  ✅ Tuckr ya está instalado"
fi

# 5. Deploy dotfiles with hooks
echo ""
echo "🔗 Deployando dotfiles con Tuckr..."
read -p "¿Usar 'tuckr set' para ejecutar hooks automáticos? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    # Deploy with hooks
    echo "  → Ejecutando tuckr set Configs/*..."
    tuckr set Configs/*
else
    # Deploy without hooks
    echo "  → Ejecutando tuckr add Configs/*..."
    tuckr add Configs/*
    echo "  ⚠️  Recuerda ejecutar manualmente los scripts de configuración"
fi

# 6. Summary
echo ""
echo "✅ Configuración inicial completada!"
echo ""
echo "📋 Próximos pasos opcionales:"
echo "  1. Reinicia tu terminal para aplicar configuraciones de shell"
echo "  2. Si usaste iTerm2 hook, reinicia iTerm2"
echo "  3. Revisa configuraciones del sistema: ./scripts/export-system-settings.sh"
echo "  4. Verifica deployment: tuckr status"
echo "  5. Lee la documentación: cat README.md"
echo ""
echo "🎨 Sistema de temas configurado automáticamente (si usaste hooks)"
echo "📚 Documentación de hooks: cat Hooks/README.md"
