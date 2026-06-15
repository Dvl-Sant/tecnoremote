#!/bin/bash
set -e

# ============================================================
# build-deb.sh - Genera el paquete .deb de TecnoRemote
# Uso: ./build-deb.sh
# Output: tecnoremote_1.4.7_amd64.deb
# ============================================================

APP_NAME="tecnoremote"
APP_VERSION="1.4.7"
APP_PUBLISHER="TECNOCOM"
MAINTAINER="TECNOCOM <soporte@tecnocom.com>"
DESCRIPTION="TecnoRemote - Soporte Remoto TECNOCOM"

# Rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUNDLE_DIR="$PROJECT_ROOT/flutter/build/linux/x64/release/bundle"
BUILD_DIR="$SCRIPT_DIR/deb-build"
PKG_DIR="$BUILD_DIR/$APP_NAME"
DEB_FILE="$SCRIPT_DIR/${APP_NAME}_${APP_VERSION}_amd64.deb"

# Verificar que el bundle existe
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "ERROR: No se encontro el bundle en:"
    echo "  $BUNDLE_DIR"
    echo "Compila primero con: cargo build --release --features flutter && cd flutter && flutter build linux --release"
    exit 1
fi

if [ ! -f "$BUNDLE_DIR/tecnoremote" ]; then
    echo "ERROR: No se encontro el binario tecnoremote en el bundle"
    exit 1
fi

echo "========================================"
echo " Construyendo $APP_NAME $APP_VERSION .deb"
echo "========================================"

# Limpiar build anterior
rm -rf "$BUILD_DIR"
mkdir -p "$PKG_DIR"

# ============================================================
# Estructura de directorios del .deb
# ============================================================

# --- DEBIAN/control ---
mkdir -p "$PKG_DIR/DEBIAN"

cat > "$PKG_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $APP_VERSION
Section: net
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libssl3, libpam0g, libpulse0, libayatana-appindicator3-1, libxcb1, libxdo4, libx11-6, libxcb-randr0, libxcb-shape0, libxcb-xfixes0, libdbus-1-3, xserver-xorg-video-dummy
Recommends: pulseaudio-utils
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 TecnoRemote es una solucion de soporte remoto basada en RustDesk,
 configurada para TECNOCOM con servidor y credenciales predefinidas.
 Incluye configuracion de monitor virtual (dummy) para PCs sin monitor fisico.
EOF

# --- DEBIAN/postinst ---
cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e

APP_NAME="tecnoremote"

# Instalar dummy display si no hay monitor fisico conectado
if ! xrandr --query 2>/dev/null | grep -q " connected"; then
    echo "[TecnoRemote] No se detecto monitor fisico, configurando display virtual..."
    
    # Asegurar que el driver dummy este instalado
    if ! dpkg -l | grep -q "xserver-xorg-video-dummy"; then
        apt-get install -y xserver-xorg-video-dummy
    fi
fi

# Crear symlink global si no existe
if [ ! -L "/usr/bin/tecnoremote" ]; then
    ln -sf /usr/lib/tecnoremote/tecnoremote /usr/bin/tecnoremote
fi

# Permisos
chmod +x /usr/lib/tecnoremote/tecnoremote
chmod +x /usr/lib/tecnoremote/lib/*.so 2>/dev/null || true

# Actualizar base de datos de desktop
update-desktop-database -q /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

echo "[TecnoRemote] Instalacion completada."
echo "[TecnoRemote] Reinicia el sistema para activar el display virtual (si es necesario)."

# Preguntar si reiniciar (no interactivo = no reiniciar)
exit 0
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

# --- DEBIAN/prerm ---
cat > "$PKG_DIR/DEBIAN/prerm" << 'PRERM'
#!/bin/bash
set -e

# Detener el servicio si esta corriendo
if systemctl is-active --quiet tecnoremote 2>/dev/null; then
    systemctl stop tecnoremote 2>/dev/null || true
fi

# Matar procesos tecnomote
pkill -f "tecnoremote" 2>/dev/null || true

exit 0
PRERM
chmod 755 "$PKG_DIR/DEBIAN/prerm"

# --- DEBIAN/postrm ---
cat > "$PKG_DIR/DEBIAN/postrm" << 'POSTRM'
#!/bin/bash
set -e

# Remover symlink
rm -f /usr/bin/tecnoremote

# Actualizar desktop database
update-desktop-database -q /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

echo "[TecnoRemote] Desinstalacion completada."

exit 0
POSTRM
chmod 755 "$PKG_DIR/DEBIAN/postrm"

# ============================================================
# Copiar archivos de la aplicacion
# ============================================================

echo "[1/5] Copiando aplicacion..."

# Binario principal
mkdir -p "$PKG_DIR/usr/lib/$APP_NAME"
cp "$BUNDLE_DIR/tecnoremote" "$PKG_DIR/usr/lib/$APP_NAME/"
chmod 755 "$PKG_DIR/usr/lib/$APP_NAME/tecnoremote"

# Librerias (.so)
mkdir -p "$PKG_DIR/usr/lib/$APP_NAME/lib"
cp "$BUNDLE_DIR"/lib/*.so "$PKG_DIR/usr/lib/$APP_NAME/lib/" 2>/dev/null || true

# Data (flutter assets, AOT, icudtl)
cp -r "$BUNDLE_DIR/data" "$PKG_DIR/usr/lib/$APP_NAME/"

# ============================================================
# Display virtual (dummy)
# ============================================================

echo "[2/5] Configurando display virtual..."

mkdir -p "$PKG_DIR/etc/X11/xorg.conf.d"

cat > "$PKG_DIR/etc/X11/xorg.conf.d/00-tecnoremote-dummy.conf" << 'DUMMYCONF'
# TecnoRemote - Configuracion de monitor virtual
# Solo se activa cuando no hay monitor fisico conectado

Section "Device"
    Identifier "TecnoRemote-Dummy"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier "TecnoRemote-Monitor"
    HorizSync 5.0 - 1000.0
    VertRefresh 5.0 - 200.0
    Modeline "1920x1080" 172.80 1920 2040 2248 2576 1080 1081 1084 1118
EndSection

Section "Screen"
    Identifier "TecnoRemote-Screen"
    Device "TecnoRemote-Dummy"
    Monitor "TecnoRemote-Monitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
        Virtual 1920 1080
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "TecnoRemote-Layout"
    Screen "TecnoRemote-Screen"
EndSection
DUMMYCONF

# ============================================================
# Iconos
# ============================================================

echo "[3/5] Copiando iconos..."

RES_DIR="$PROJECT_ROOT/res"

for SIZE in 32x32 64x64 128x128; do
    ICON_DIR="$PKG_DIR/usr/share/icons/hicolor/$SIZE/apps"
    mkdir -p "$ICON_DIR"
    
    case $SIZE in
        32x32)  ICON_FILE="$RES_DIR/32x32.png" ;;
        64x64)  ICON_FILE="$RES_DIR/64x64.png" ;;
        128x128) ICON_FILE="$RES_DIR/128x128.png" ;;
    esac
    
    if [ -f "$ICON_FILE" ]; then
        cp "$ICON_FILE" "$ICON_DIR/tecnoremote.png"
    fi
done

# 256x256 desde icon.png o 128x128@2x
ICON_256="$RES_DIR/128x128@2x.png"
if [ -f "$ICON_256" ]; then
    ICON_DIR="$PKG_DIR/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "$ICON_DIR"
    cp "$ICON_256" "$ICON_DIR/tecnoremote.png"
fi

# ============================================================
# Desktop entry + Autostart
# ============================================================

echo "[4/5] Creando shortcuts..."

mkdir -p "$PKG_DIR/usr/share/applications"

cat > "$PKG_DIR/usr/share/applications/tecnoremote.desktop" << 'DESKTOP'
[Desktop Entry]
Name=TecnoRemote
GenericName=Remote Desktop
Comment=Soporte Remoto TECNOCOM
Exec=tecnoremote %u
Icon=tecnoremote
Terminal=false
Type=Application
StartupNotify=true
Categories=Network;RemoteAccess;GTK;
Keywords=internet;remote-control;remote-desktop;
StartupWMClass=tecnoremote

[Desktop Action new-window]
Name=Open a New Window
Exec=tecnoremote %u
DESKTOP

# Autostart
mkdir -p "$PKG_DIR/etc/xdg/autostart"
cp "$PKG_DIR/usr/share/applications/tecnoremote.desktop" \
   "$PKG_DIR/etc/xdg/autostart/tecnoremote.desktop"

# ============================================================
# License
# ============================================================

mkdir -p "$PKG_DIR/usr/share/doc/$APP_NAME"
cat > "$PKG_DIR/usr/share/doc/$APP_NAME/copyright" << 'COPYRIGHT'
TecnoRemote - Soporte Remoto TECNOCOM
Copyright (c) 2026 TECNOCOM. All rights reserved.

Basado en RustDesk (https://rustdesk.com)
RustDesk Copyright (c) 2022 Purslane Ltd.
Licencia: GPL-3.0
COPYRIGHT

# ============================================================
# Construir el .deb
# ============================================================

echo "[5/5] Construyendo paquete .deb..."

# Permisos correctos
find "$PKG_DIR" -type d -exec chmod 755 {} \;
chmod 755 "$PKG_DIR/DEBIAN/postinst" "$PKG_DIR/DEBIAN/prerm" "$PKG_DIR/DEBIAN/postrm"

# dpkg-deb
dpkg-deb --build --root-owner-flag "$PKG_DIR" "$DEB_FILE"

echo ""
echo "========================================"
echo " BUILD COMPLETADO"
echo "========================================"
echo ""
echo "Archivo: $DEB_FILE"
echo "Tamano:  $(du -h "$DEB_FILE" | cut -f1)"
echo ""
echo "Para instalar:"
echo "  sudo apt install ./${APP_NAME}_${APP_VERSION}_amd64.deb"
echo ""
echo "Para desinstalar:"
echo "  sudo apt remove $APP_NAME"
