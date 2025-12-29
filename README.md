# Exportar ROMs Favoritas

Este proyecto contiene scripts para copiar automáticamente tus ROMs favoritas desde las carpetas de sistemas, con sus imágenes asociadas, a una carpeta de exportación.
Por defecto ignora la carpeta "ports".

Hay una versión **Linux** y otra **Windows** (PowerShell).

---

# Scripts:

- `copiar_favoritos.sh` → Script Bash para Linux
- `copiar_favoritos.ps1` → Script PowerShell para Windows

---

# Uso:

## Linux

- Coloca el script `copiar_favoritos.sh` en la carpeta raíz de tus sistemas.
- Ejecuta: copiar_favoritos.sh

## Windows

- Coloca `copiar_favoritos.ps1` en la carpeta raíz de tus sistemas.

- Ejecuta PowerShell:

Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\copiar_favoritos.ps1

## Personalización

Cambiar carpeta de favoritos: $FAVPATH (Linux) / $FavPath (Windows)

Ignorar otros sistemas: modifica la condición que compara $system
