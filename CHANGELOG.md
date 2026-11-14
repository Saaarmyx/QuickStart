# Historial de cambios

> Todos los cambios notables de este proyecto se documentarán en este archivo.

## QuickStart 0.3

### 2026-11-14

- Agregado
  - Artcraft Launcher en categoría Gaming como paquete `.deb` (launcher de código abierto para apps de Craft).
  - Persistencia de credenciales de Git con `credential.helper store` y libsecret.
  - Artcraft incluido en el perfil `gamedev`.

- Corregido
  - Discord: cambiado de `.deb` a `snap` para evitar error de instalación por URL con query params.
  - Zen Browser: instalación de `fuse2` antes de extraer el AppImage (requerido en Ubuntu 24.04+).

## QuickStart 0.2

### 2026-11-14

- Agregado
  - Banner con imagen `Saaarmyx-Github.svg` y enlace a la página principal.
  - Sección "Descripción" con descripción detallada del instalador interactivo.
  - Sección "Características principales" con lista de funcionalidades: menú interactivo, perfiles rápidos, motores de instalación y CLI.

- Mejorado
  - Se actualizaron los enlaces de la tabla de contenidos para incluir las nuevas secciones.

## QuickStart 0.1

### 2026-10-13

- Agregado
  - Primer commit con la estructura base del proyecto: script principal `quick_start.sh` con menú interactivo y CLI, scripts de soporte en `lib/`, tema GTK MacTahoe-Dark en `themes/`, validador y pruebas en `tests/`, catálogo de más de 110 aplicaciones en 12 categorías, 10 perfiles rápidos y seis motores de instalación, `README.md`, `CHANGELOG.md`, `LICENSE` y `NOTICE`.

---

<p align="center">
  Desarrollado por <strong>Saaarmyx</strong>.
</p>
