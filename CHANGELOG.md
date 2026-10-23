# Changelog

Todos los cambios relevantes de QuickStart se anotan aquí.

El formato sigue [Keep a Changelog 1.1.0](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto usa [Versionado Semántico](https://semver.org/lang/es/).

## [Sin publicar]

### Añadido

- Base del sistema obligatoria: `git` se instala siempre primero y, si el equipo lleva el chip, se ofrece el driver Wi-Fi MediaTek MT7902.
- Detección del driver Wi-Fi con `lspci`, `lsusb` y `/sys`. Si el chip no coincide, la opción no aparece.
- Desinstalación de apps del catálogo desde el menú (`D`) o con `--desinstalar`.
- Protección de paquetes base: no se purga nada que deje el sistema inservible.
- Personalización del escritorio con el tema MacTahoe-Dark y los iconos WhiteSur opcionales.
- Spotify instalado con `--classic`.

### Cambiado

- La licencia del proyecto pasa de MIT a Apache License 2.0 (`Apache-2.0`).
- El proyecto pasó de llamarse InicioRapido a QuickStart, con logs en `/tmp/quickstart-*.log`.
- La guía de contribución se amplió con el formato del catálogo y los perfiles.

### Corregido

- Zen Browser ya arranca en Ubuntu 24.04+ al extraer el AppImage y apuntar el lanzador a `AppRun`.
- Visual Studio Code usa el repositorio oficial de Microsoft en lugar de un `.deb` suelto.
- OpenCode usa npm cuando está disponible y comprueba sus rutas reales.
- El modo simulación ya no descarga packs de iconos.

## [1.0.0] - 2026-10-13

Primera versión pública. Reúne en una sola herramienta con menú tres scripts previos del autor: instalación limpia, driver Wi-Fi y utilidades.

### Añadido

- Menú interactivo con 12 categorías y selección múltiple acumulada.
- Menú de perfiles rápidos con 10 combinaciones predefinidas.
- Catálogo de 112 aplicaciones: navegadores, lenguajes y runtimes, editores, contenedores y DevOps, bases de datos, social y comunicación, productividad, multimedia y diseño, gaming, terminal y utilidades, red y seguridad, e IA y asistentes.
- Lenguajes y runtimes: Python, Pyenv, uv, Jupyter, Node.js con NVM, Bun, Deno, Rust con rustup, Go, OpenJDK, PHP con Composer, Ruby, .NET SDK, Elixir y R con RStudio.
- Social y comunicación: Discord, Telegram, Signal, Slack, Element, WhatsApp, Zoom y Microsoft Teams.
- Seis motores de instalación: `apt`, `snap`, `flatpak`, `deb`, `ppa` y `custom`.
- Manejadores propios para rustup, NVM, el tarball de Go, uv, Bun, Deno, dotnet-install, los repositorios de Firefox, Brave y GitHub CLI, Neovim, Android CLI, OpenCode, Claude Code, Ollama, Docker, Wireshark y FFmpeg.
- Detección automática de lo ya instalado.
- Preparación de `snapd` y Flathub cuando la selección lo requiere.
- Modificación idempotente del `PATH` en `~/.bashrc` y `~/.profile`.
- Informe final con instaladas, omitidas y fallidas.
- Registro con `tee`, por defecto en `/tmp` y configurable con `--log`.
- Modo simulación con `--simular` o `--dry-run`.
- CLI completa: `--instalar`, `--perfil`, `--categoria`, `--todos`, `--forzar`, `--listar`, `--listar-perfiles`, `--si` y `--ayuda`.
- Validador de catálogo en `tests/validar_catalogo.sh`.
- Documentación en `README.md` y `docs/CONTRIBUTING.md`.
- Licencia MIT en esa versión.

### Decisiones

- El script no desinstala nada por su cuenta. Los `.deb` oficiales se instalan con `apt` para que `sudo apt purge` siga funcionando.
- El registro se activa tras la confirmación, para que los menús no se mezclen con la salida de instalación.
- Los `.deb` exclusivos de `amd64` se omiten con aviso en `arm64` en lugar de fallar.

[Sin publicar]: https://github.com/Saaarmyx/QuickStart/commits/main

<!-- TODO: añadir enlaces de comparación entre versiones cuando el repositorio tenga tags. -->
