# macOS System Settings

Este directorio contiene las configuraciones exportadas del sistema macOS.

## Archivos

- `defaults/` - Preferencias exportadas con `defaults read`
- `LaunchAgents/` - Agentes de usuario personalizados
- `restore-settings.sh` - Script para restaurar configuraciones (⚠️ usar con precaución)

## Uso

### Exportar configuraciones actuales
```bash
./scripts/export-system-settings.sh
```

### Ver diferencias
```bash
git diff system-settings/
```

## ⚠️ Advertencias

- **NO** ejecutar `restore-settings.sh` ciegamente en un sistema nuevo
- Revisar cada archivo antes de aplicar
- Algunas configuraciones pueden ser específicas del hardware
- Algunas preferencias pueden requerir reiniciar el sistema o logout/login

## Configuraciones importantes

### Dock
- Tamaño, posición, auto-hide
- Apps favoritas (se almacenan como referencias de archivo)

### Finder
- Vista por defecto, extensiones de archivo
- Carpetas en sidebar

### Global
- Teclado, trackpad, mouse
- Apariencia (modo oscuro/claro)
- Idioma y región
