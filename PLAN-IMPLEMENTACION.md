# TecnoRemote - Plan de Implementacion

## Contexto del Proyecto

| Item | Detalle |
|---|---|
| **Fork** | `Dvl-Sant/tecnoremote` (basado en `rustdesk/rustdesk` v1.4.7) |
| **Repo local** | `C:\Users\jdsan\Documents\2.- Proyectos\tecnoremote` |
| **Nombre del producto** | TecnoRemote |
| **Empresa** | TECNOCOM |
| **Servidor** | `31.220.107.123` (Dokploy en Hostinger) |
| **Key** | `4VlBtYxNw5oCVBZhG9M1sDi2PzWhJo5zjgm3cwNlXXc=` |
| **Contraseña default** | `Tecnocom2026` |
| **Flutter** | 3.44.1 instalado en `C:\flutter` |
| **Rust** | NO instalado aun (necesario para compilar) |

---

## Herramientas que faltan instalar

| Herramienta | Para que | Install |
|---|---|---|
| **Rust toolchain** | Compilar el core nativo | `scoop install rustup` -> `rustup default stable` |
| **vcpkg** | Dependencias C/C++ (libvpx, libyuv, opus, aom) | Clonar + bootstrap + instalar deps |
| **Visual Studio Build Tools** | Compilador C++ para Windows | Descargar desde Microsoft |

---

## FASE 1: Configuracion del entorno (1-2 dias)

### Tarea 1.1: Instalar Rust toolchain
```
scoop install rustup
rustup default stable
rustc --version
```

### Tarea 1.2: Instalar Visual Studio Build Tools 2022
- Descargar desde: https://visualstudio.microsoft.com/visual-cpp-build-tools/
- Seleccionar: "Desktop development with C++"
- Incluir: Windows SDK, MSVC v143

### Tarea 1.3: Instalar vcpkg y dependencias
```
git clone https://github.com/microsoft/vcpkg C:\vcpkg
cd C:\vcpkg && git checkout 2023.04.15
.\bootstrap-vcpkg.bat
setx VCPKG_ROOT "C:\vcpkg"
vcpkg install libvpx:x64-windows-static libyuv:x64-windows-static opus:x64-windows-static aom:x64-windows-static
```

### Tarea 1.4: Verificar que compila el proyecto original (sin cambios)
```
cd C:\Users\jdsan\Documents\2.- Proyectos\tecnoremote
cargo build --release
```
Si compila, el entorno esta listo.

---

## FASE 2: Nombre interno - cambios criticos (~15 archivos)

**Objetivo:** La app se llama "TecnoRemote" internamente y compila.

### Tarea 2.1: Cambiar APP_NAME en Rust (el mas importante)

| Archivo | Linea | Cambio |
|---|---|---|
| `libs/hbb_common/src/config.rs` | 72 | `"RustDesk"` -> `"TecnoRemote"` |
| `src/common.rs` | 1009-1011 | Actualizar `is_rustdesk()` -> `is_tecnoremote()` o ajustar logica |

### Tarea 2.2: Cambiar Cargo.toml

| Archivo | Cambio |
|---|---|
| `Cargo.toml:2` | `name = "tecnoremote"` |
| `Cargo.toml:4` | `authors = ["TECNOCOM <soporte@tecnocom.com>"]` |
| `Cargo.toml:7` | `description = "TecnoRemote - Soporte Remoto TECNOCOM"` |
| `Cargo.toml:8` | `default-run = "tecnoremote"` |
| `Cargo.toml:12` | `name = "libtecnoremote"` |
| `Cargo.toml:217-219` | Windows: ProductName, FileDescription, OriginalFilename -> TecnoRemote |
| `Cargo.toml:235-236` | macOS: name, identifier -> TecnoRemote |
| `libs/portable/Cargo.toml` | name, description, product metadata -> TecnoRemote |

### Tarea 2.3: Cambiar configs nativas Windows

| Archivo | Cambio |
|---|---|
| `flutter/windows/runner/main.cpp:66` | `L"RustDesk"` -> `L"TecnoRemote"` |
| `flutter/windows/runner/Runner.rc:92-98` | CompanyName, FileDescription, ProductName, etc -> TecnoRemote / TECNOCOM |

### Tarea 2.4: Cambiar configs nativas Android

| Archivo | Cambio |
|---|---|
| `flutter/android/app/src/main/AndroidManifest.xml` | `android:label="TecnoRemote"` |
| `flutter/android/app/src/main/res/values/strings.xml` | `app_name` -> `TecnoRemote` |

### Tarea 2.5: Cambiar configs nativas iOS/macOS

| Archivo | Cambio |
|---|---|
| `flutter/ios/Runner/Info.plist` | CFBundleDisplayName, CFBundleName -> TecnoRemote |
| `flutter/macos/Runner/Configs/AppInfo.xcconfig` | PRODUCT_NAME = TecnoRemote |

### Tarea 2.6: Cambiar en Flutter/Dart los strings criticos

| Archivo | Cambio |
|---|---|
| `flutter/lib/web/bridge.dart:1612` | `"RustDesk"` -> `"TecnoRemote"` en custom client check |
| `flutter/lib/desktop/widgets/tabbar_widget.dart:644` | `"RustDesk"` -> `"TecnoRemote"` |

### Tarea 2.7: Cambiar Linux .desktop y .service

| Archivo | Cambio |
|---|---|
| `res/rustdesk.desktop` | Rename a `tecnoremote.desktop`, cambiar Name, Exec, Icon |
| `res/rustdesk-link.desktop` | Rename, cambiar scheme handler |
| `res/rustdesk.service` | Rename, cambiar Description, Exec |

### Verificacion Fase 2
```
cargo build --release
```
Debe compilar sin errores.

---

## FASE 3: Hardcodeo de servidor y configuracion (~5 archivos)

**Objetivo:** TecnoRemote viene preconfigurado con el servidor de TECNOCOM.

### Tarea 3.1: Hardcodear servidor en el codigo Rust

| Archivo | Cambio |
|---|---|
| `libs/hbb_common/src/config.rs` | Default `custom-rendezvous-server` = `"31.220.107.123"` |
| `libs/hbb_common/src/config.rs` | Default `relay-server` = `"31.220.107.123"` |
| `libs/hbb_common/src/config.rs` | Default `key` = `"4VlBtYxNw5oCVBZhG9M1sDi2PzWhJo5zjgm3cwNlXXc="` |

### Tarea 3.2: Hardcodear contrasena por defecto

| Archivo | Cambio |
|---|---|
| `libs/hbb_common/src/config.rs` o equivalente | Setear `Tecnocom2026` como password permanente por defecto en primer arranque |

### Tarea 3.3: Ocultar/deshabilitar Settings -> Network (opcional)

| Archivo | Cambio |
|---|---|
| `flutter/lib/desktop/pages/desktop_setting_page.dart` | Ocultar seccion de configuracion de red o marcarla read-only |

### Verificacion Fase 3
La app se conecta automaticamente al servidor sin configuracion manual.

---

## FASE 4: Branding visual (~70 archivos)

### Tarea 4.1: Colores del tema

| Archivo | Cambio |
|---|---|
| `flutter/lib/common.dart:254` | `accent` -> color primario TECNOCOM |
| `flutter/lib/common.dart:263` | `button` -> color boton TECNOCOM |
| `flutter/lib/desktop/widgets/titlebar_widget.dart:3-5` | Gradiente titlebar -> colores TECNOCOM |

### Tarea 4.2: Iconos - generar con el logo TECNOCOM

Reemplazar TODOS los archivos de iconos:

**Flutter assets:**
- `flutter/assets/icon.svg`

**Windows:**
- `flutter/windows/runner/resources/app_icon.ico`

**Android (~20 archivos):**
- `flutter/android/app/src/main/res/mipmap-*/*`

**iOS (~18 archivos):**
- `flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset/*`

**macOS:**
- `flutter/macos/Runner/AppIcon.icns`

**res/ (~10 archivos):**
- `res/icon.png`, `res/icon.ico`, `res/*.png`, `res/*.svg`

**Herramienta recomendada:** `flutter pub run flutter_launcher_icons` para generar todos desde un solo icono source.

### Tarea 4.3: Textos visibles al usuario

Buscar y reemplazar `"RustDesk"` -> `"TecnoRemote"` en todos los archivos Dart:

- `flutter/lib/mobile/pages/settings_page.dart`
- `flutter/lib/desktop/pages/desktop_setting_page.dart`
- `flutter/lib/desktop/pages/desktop_home_page.dart`
- `flutter/lib/mobile/pages/connection_page.dart`
- `flutter/lib/desktop/pages/connection_page.dart`
- `flutter/lib/desktop/pages/install_page.dart`
- `flutter/lib/common.dart`
- `src/lang/` (archivos de traduccion)

### Tarea 4.4: URLs

| Cambio | De | A |
|---|---|---|
| Sitio web | `rustdesk.com` | URL de TECNOCOM o dejar vacio |
| Privacy | `rustdesk.com/privacy.html` | URL propia o dejar vacio |
| Download | `rustdesk.com/download` | URL propia o dejar vacio |
| GitHub | `github.com/rustdesk/...` | `github.com/Dvl-Sant/tecnoremote` |

### Tarea 4.5: Method channels y deep links

| Archivo | Cambio |
|---|---|
| `flutter/lib/utils/platform_channel.dart:17` | `"org.rustdesk.rustdesk/host"` -> `"com.tecnocom.tecnoremote/host"` |
| `flutter/lib/models/native_model.dart:121-131` | `"librustdesk.so"` -> `"libtecnoremote.so"`, etc. |
| `flutter/lib/mobile/pages/home_page.dart:191` | `"rustdesk://..."` -> `"tecnoremote://..."` |
| `flutter/lib/common.dart:2226,2384,2405,2430` | `rustdesk://` -> `tecnoremote://` |

### Verificacion Fase 4
La app muestra TecnoRemote como nombre, colores TECNOCOM, y logo propio.

---

## FASE 5: Build y distribucion

### Tarea 5.1: Compilar para Windows
```
cd tecnoremote
cargo build --release --features flutter
flutter build windows --release
```

### Tarea 5.2: Crear installer Windows
- Usar NSIS o Inno Setup con el `.exe` resultante
- Incluir config predefinida

### Tarea 5.3: Compilar para Android (si se necesita)
```
flutter build apk --release
```

### Tarea 5.4: Configurar CI/CD (GitHub Actions)
- Build automatico en push a `main`
- Generar releases para Win/Android

---

## Timeline estimado

| Fase | Duracion | Dependencia |
|---|---|---|
| **Fase 1:** Entorno | 1-2 dias | Instalar Rust, VS Build Tools, vcpkg |
| **Fase 2:** Nombre interno | 1 dia | Entorno listo |
| **Fase 3:** Servidor hardcodeado | 0.5 dias | Fase 2 completada |
| **Fase 4:** Branding visual | 2-3 dias | Logo TECNOCOM disenado |
| **Fase 5:** Build + CI/CD | 1-2 dias | Fases 2-4 completadas |

**Total estimado:** 5-8 dias laborales

---

## Lo que ya esta hecho y funcional

- Servidor RustDesk deployado en Dokploy (`31.220.107.123`)
  - hbbs (senalizacion) + hbbr (relay) corriendo
  - Puertos 21115-21119 abiertos y verificados
- Paquete de deployment Camino A en `C:\Users\jdsan\Documents\2.- Proyectos\TecnoRemote-Deploy\`
  - `instalar-tecnoremote.bat` + `.ps1` (Windows, probado y funcionando)
  - `instalar-tecnoremote-linux.sh` (no probado)
  - `instalar-tecnoremote-macos.sh` (no probado)
  - `RustDesk2.toml` con config predefinida
  - `INSTRUCCIONES.txt`
- Flutter SDK 3.44.1 instalado en `C:\flutter`
- Fork clonado en `C:\Users\jdsan\Documents\2.- Proyectos\tecnoremote`
- Scoop instalado (gestor de paquetes)
- Gentle-AI + Engram instalados (memoria persistente para agentes)

---

## Consideraciones legales

- RustDesk tiene licencia **AGPLv3** (copyleft fuerte)
- Uso interno = no hay obligacion de liberar codigo
- Si se distribuye fuera de la empresa, hay que liberar los cambios bajo AGPLv3
- Fork con branding propio para uso interno = 100% legal
- No remover la licencia original ni los creditos de RustDesk
