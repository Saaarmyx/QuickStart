# Changelog

Todas las novedades relevantes de InicioRapido se anotan aquí.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y
el proyecto usa [versionado semántico](https://semver.org/lang/es/).

## [No publicado]

Aún no hay cambios pendientes de publicar.

## [1.0.0] - 2026-10-13

Primera versión pública. Reúne en una sola herramienta con menú tres scripts
previos del autor: instalación limpia, driver Wi-Fi y utilidades.

### Añadido

- Menú interactivo con 12 categorías y selección múltiple con acumulación
  entre categorías.
- Menú de perfiles rápidos con 10 combinaciones predefinidas.
- Catálogo de 112 aplicaciones: navegadores, lenguajes y runtimes, editores,
  contenedores y DevOps, bases de datos, social y comunicación,
  productividad, multimedia y diseño, gaming, terminal y utilidades, red y
  seguridad, e IA y asistentes.
- Lenguajes y runtimes: Python, Pyenv, uv, Jupyter, Node.js con NVM, Bun,
  Deno, Rust con rustup, Go, OpenJDK, PHP con Composer, Ruby, .NET SDK,
  Elixir y R con RStudio.
- Social y comunicación: Discord, Telegram, Signal, Slack, Element,
  WhatsApp, Zoom y Microsoft Teams.
- Seis motores de instalación: `apt`, `snap`, `flatpak`, `deb`, `ppa` y
  `custom`.
- Manejadores propios para lo que `apt` no resuelve: rustup, NVM, el
  tarball oficial de Go, uv, Bun, Deno, dotnet-install, los repositorios
  oficiales de Firefox, Brave y GitHub CLI, los tarballs de Neovim, las
  herramientas de línea de comandos de Android, OpenCode, Claude Code,
  Ollama, Docker y los paquetes que piden confirmación (Wireshark, FFmpeg
  con códecs).
- Detección automática de lo ya instalado para no repetir trabajo.
- Preparación automática de `snapd` y del repositorio de Flathub cuando la
  selección lo requiere.
- Modificación idempotente del `PATH` en `~/.bashrc` y `~/.profile`.
- Informe final que separa instaladas, omitidas y fallidas.
- Registro de la instalación con `tee`, por defecto en `/tmp` y configurable
  con `--log`.
- Modo simulación con `--simular` o `--dry-run`.
- Interfaz de línea de comandos completa: `--instalar`, `--perfil`,
  `--categoria`, `--todos`, `--forzar`, `--listar`, `--listar-perfiles`,
  `--si` y `--ayuda`.
- Validador de catálogo en `tests/validar_catalogo.sh`.
- Documentación en `README.md` y `docs/CONTRIBUTING.md`.
- Licencia MIT.

### Decisiones

- El script no desinstala nada. Los `.deb` oficiales se instalan con `apt`
  para que `sudo apt purge` siga funcionando.
- El registro se activa tras la confirmación, de modo que los menús no se
  mezclan con la salida de instalación.
- Los `.deb` exclusivos de `amd64` se omiten con aviso en `arm64` en lugar de
  fallar.

[No publicado]: https://github.com/Saaarmyx/InicioRapido/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Saaarmyx/InicioRapido/releases/tag/v1.0.0
