#!/bin/bash
# Aerospace post-hook: Configure aerospace to start on login

echo "🚀 Configurando Aerospace..."

# Start aerospace service if not running
if command -v aerospace &>/dev/null; then
    if ! pgrep -x "AeroSpace" &>/dev/null; then
        echo "  → Iniciando Aerospace..."
        open -a AeroSpace
        echo "  ✅ Aerospace iniciado"
    else
        echo "  ✅ Aerospace ya está ejecutándose"
    fi
    
    echo "  ℹ️  Para iniciar automáticamente al login:"
    echo "     System Settings → General → Login Items → Add AeroSpace"
else
    echo "  ⚠️  Aerospace no está instalado"
    echo "     Instala: brew install --cask nikitabobko/tap/aerospace"
fi
