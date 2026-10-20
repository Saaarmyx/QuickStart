# QuickStart

> Instalador interactivo de aplicaciones para Ubuntu. Elige lo que quieres de un menú y déjalo instalado.

Un solo script, en español, que instala más de **110 aplicaciones** repartidas en **12 categorías**, con **10 perfiles listos** para los casos más habituales. No desinstala nada por sorpresa, detecta lo que ya tienes y deja un registro de todo lo que hizo.

Nace de tres scripts que viene usando el autor para preparar máquinas nuevas: instalación limpia, driver Wi-Fi y utilidades. Aquí se fusionan en una sola herramienta con menú.

---

## Índice

- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Categorías](#categorías)
- [Perfiles](#perfiles)
- [Opciones de línea de comandos](#opciones-de-línea-de-comandos)
- [Cómo funciona](#cómo-funciona)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Añadir una aplicación](#añadir-una-aplicación)
- [Registro y diagnóstico](#registro-y-diagnóstico)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

---

## Requisitos

| Requisito    | Detalle                                                                                                |
| ------------ | ------------------------------------------------------------------------------------------------------ |
| Sistema      | Ubuntu 24.04 LTS o 26.04 LTS. En otras distribuciones se avisa y se detiene.                           |
| Arquitectura | `amd64` completa. En `arm64` funciona, pero se omiten los `.deb` que no existen para esa arquitectura. |
| Privilegios  | Tu usuario normal con `sudo`. **No** ejecutes el script como root.                                     |
| Red          | Necesaria para descargar índices e instaladores.                                                       |
| Dependencias | Solo `bash`, `dpkg` y `sudo`. El propio script instala `curl` y `wget` si faltan.                      |

Probado en Ubuntu 24.04 LTS y 26.04 LTS (alias `resolute`).

---

## Instalación

```bash
git clone https://github.com/Saaarmyx/QuickStart.git
cd QuickStart
chmod +x quick_start.sh
./quick_start.sh
```

No hay nada que compilar ni dependencias que instalar: es bash puro.

---

## Uso

Ejecuta el script sin argumentos y entra al menú:

```bash
./quick_start.sh
```

```
============================================================
  QuickStart · instalador de aplicaciones
============================================================

   1) Navegadores              (1)
   2) Lenguajes y runtimes     (2)
   3) Editores e IDEs          (0)
   4) Contenedores y DevOps    (0)
   5) Bases de datos           (0)
   6) Social y comunicación    (3)
   7) Productividad            (0)
   8) Multimedia y diseño      (0)
   9) Gaming                   (0)
  10) Terminal y utilidades    (0)
  11) Red y seguridad          (0)
  12) IA y asistentes          (0)

  P)  Perfiles rápidos
  C)  Catálogo completo
  0)  Continuar con la instalación

  Seleccionadas                    6
```

Al entrar en una categoría marcas y desmarcas con los números:

```
  [x]  1) Zen Browser              instalador
  [x]  2) Mozilla Firefox          instalador
  [ ]  3) Google Chrome            deb
  [ ]  4) Brave Browser            instalador

  Comandos: todos · ninguno · v (volver)
```

La selección **se acumula** entre categorías. Al terminar ves el resumen completo, confirmas una sola vez y empieza la instalación.

### Flujo de una instalación

1. Comprobaciones: distribución, arquitectura, `sudo`, red.
2. **Base del sistema**: `git` siempre primero y, si el hardware coincide, el driver Wi-Fi.
3. Menú de selección.
4. Resumen agrupado por categoría con confirmación.
5. `apt update` y reparación de paquetes a medias.
6. Preparación de `snapd` o Flathub si la selección lo necesita.
7. Instalación app por app, saltando lo ya instalado.
8. Reparación final e informe de qué se instaló, omitió y falló.

---

## Base del sistema: git y driver Wi-Fi

Antes de cualquier app se instala la base:

- **`git`** se instala siempre primero, porque sin él no se pueden clonar drivers ni repositorios.
- **Driver Wi-Fi MediaTek MT7902** solo se ofrece si el chip está realmente en la máquina. Se detecta con `lspci`, `lsusb` y `/sys`; si el equipo no lleva ese chip, la opción **no aparece ni se menciona**.

El driver se clona desde su repositorio oficial y se ejecuta su instalador. Si ya está cargado el módulo, se omite.

---

## Personalización: tema e iconos

Incluye el tema GTK **MacTahoe-Dark** en [`themes/`](themes/). Es opcional y nunca se instala solo: se pide desde el menú (`T) Personalización`) o con `--tema`.

```bash
./quick_start.sh --tema
```

Qué hace:

1. Copia el tema a `~/.themes`.
2. Si aceptas, descarga iconos y cursores **WhiteSur** a `~/.icons`.
3. Aplica todo con `gsettings` en sesiones GNOME.
4. Ofrece instalar `gnome-tweaks` para gestionarlo desde un panel.

Para deshacerlo, la función `tema_quitar` de `lib/themes.sh` restaura el tema Yaru del sistema y borra lo instalado.

---

## Desinstalar aplicaciones

Puedes quitar lo que el catálogo instaló, desde el menú (`D) Desinstalar`) o con:

```bash
./quick_start.sh --desinstalar
```

Lista solo las apps del catálogo que están presentes en el equipo y las quita con el gestor que corresponde: `apt purge`, `snap remove` o `flatpak uninstall`, y desinstaladores propios para las que se instalan a mano.

**Protección de paquetes base**: hay apps cuyo paquete no se puede purgar sin dejar el sistema inservible (`python3`, por ejemplo, lo usan `apt` y media distro). Esas se detectan y se niegan con un aviso explicando el motivo, en lugar de romperte el equipo.

---

## Categorías

| #   | Categoría             | Contenido                                                                                                                                             |
| --- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Navegadores           | Zen, Firefox, Chrome, Brave                                                                                                                           |
| 2   | Lenguajes y runtimes  | Python, Pyenv, uv, Jupyter, Node + NVM, Bun, Deno, Rust, Go, Java, PHP, Ruby, .NET, Elixir, R                                                         |
| 3   | Editores e IDEs       | VS Code, VS Codium, Zed, Sublime Text, JetBrains Toolbox, Android Studio, Neovim, Vim, Emacs                                                          |
| 4   | Contenedores y DevOps | Git, Docker, Podman, kubectl, Helm, Minikube, Ansible, Terraform, GitHub CLI, Postman, Insomnia, DBeaver, LazyGit, GitHub Desktop                     |
| 5   | Bases de datos        | Clientes de PostgreSQL, MySQL, Redis y SQLite                                                                                                         |
| 6   | Social y comunicación | Discord, Telegram, Signal, Slack, Element, WhatsApp, Zoom, Teams                                                                                      |
| 7   | Productividad         | LibreOffice, Obsidian, Joplin, Bitwarden, KeePassXC, Synaptic, ajustes de GNOME, fuentes, Timeshift                                                   |
| 8   | Multimedia y diseño   | Spotify, VLC, Celluloid, FFmpeg, Audacity, OBS, Kdenlive, HandBrake, GIMP, Inkscape, Krita, Blender, yt-dlp                                           |
| 9   | Gaming                | Steam, Lutris, Heroic, Gamescope, ProtonUp-Qt, MangoHud                                                                                               |
| 10  | Terminal y utilidades | btop, htop, fastfetch, bat, eza, ripgrep, fd, fzf, tldr, jq, yq, ShellCheck, Starship, Zsh, Fish, terminales, tmux, archivadores, ImageMagick, Pandoc |
| 11  | Red y seguridad       | OpenSSH, UFW, Fail2ban, Wireshark, Nmap, herramientas de red, medidores de velocidad                                                                  |
| 12  | IA y asistentes       | OpenCode, Claude Code, Ollama, ChatGPT                                                                                                                |

Lista completa con los identificadores de cada entrada:

```bash
./quick_start.sh --listar
```

---

## Perfiles

Atajos a grupos de apps que suelen ir juntas.

```bash
./quick_start.sh --perfil devops
```

| Perfil       | Qué instala                                                  |
| ------------ | ------------------------------------------------------------ |
| `minimal`    | Lo esencial del día a día                                    |
| `frontend`   | Node, Bun, Python, editores, navegadores, Postman            |
| `backend`    | Node, Python, Docker, clientes de PostgreSQL y MySQL         |
| `data`       | Python, uv, Jupyter, R, DBeaver                              |
| `devops`     | Docker, Podman, Kubernetes, Ansible, Terraform, `gh`         |
| `mobile`     | Android Studio, Node, Python, Insomnia                       |
| `multimedia` | FFmpeg, editores de vídeo y audio, GIMP, Inkscape            |
| `gamedev`    | Steam, Lutris, Heroic, Gamescope, MangoHud                   |
| `social`     | Discord, Telegram, Signal, Slack, Element, WhatsApp, Spotify |
| `privacidad` | Zen, Signal, gestores de contraseñas, UFW                    |

```bash
./quick_start.sh --listar-perfiles
```

---

## Opciones de línea de comandos

Todo se puede automatizar, sin menús.

| Opción                   | Qué hace                                         |
| ------------------------ | ------------------------------------------------ |
| `--instalar LISTA`       | Instala los ids indicados, separados por comas.  |
| `--perfil NOMBRE`        | Aplica un perfil.                                |
| `--categoria NOMBRE`     | Selecciona una categoría completa. Admite comas. |
| `--todos`                | Selecciona el catálogo entero.                   |
| `--sin-menu`             | Instala directamente lo indicado.                |
| `--si`, `--yes`, `-y`    | No pide confirmación final.                      |
| `--simular`, `--dry-run` | Muestra qué haría sin tocar nada.                |
| `--forzar`               | Reinstala aunque la app ya esté presente.        |
| `--listar`               | Lista el catálogo y termina.                     |
| `--listar-perfiles`      | Lista los perfiles y termina.                    |
| `--desinstalar`          | Entra al modo de desinstalación.                |
| `--tema`                 | Instala y aplica el tema incluido (GNOME).       |
| `--log RUTA`             | Guarda el registro en la ruta indicada.          |
| `--no-color`             | Desactiva los colores.                           |
| `--ayuda`, `-h`          | Ayuda.                                           |

Variables de entorno: `ASSUME_YES=1`, `NO_COLOR=1`, `LOG_FILE`.

### Ejemplos

```bash
# Ver qué haría un perfil, sin instalar nada
./quick_start.sh --perfil devops --simular

# Dejar un equipo de backend listo, sin preguntas
./quick_start.sh --perfil backend --si

# Sólo unas pocas herramientas
./quick_start.sh --instalar node,rust,python,vscode

# Una categoría entera, más el perfil de gaming
./quick_start.sh --categoria "Terminal y utilidades" --perfil gamedev --si
```

Integración en una máquina de producción o en un script de provisioning:

```bash
ASSUME_YES=1 ./quick_start.sh --perfil devops --log /var/log/quickstart.log
```

---

## Cómo funciona

Cada aplicación del catálogo declara **cómo** instalarse:

| Tipo      | Qué hace                                                               |
| --------- | ---------------------------------------------------------------------- |
| `apt`     | `sudo apt install -y` con los paquetes indicados.                      |
| `snap`    | Instala `snapd` si falta y luego `sudo snap install`.                  |
| `flatpak` | Añade Flathub si falta y luego `sudo flatpak install`.                 |
| `deb`     | Descarga el `.deb` a un temporal y lo instala con `apt`.               |
| `ppa`     | Añade el PPA con `add-apt-repository` y instala el paquete.            |
| `custom`  | Manejador propio en `lib/installers.sh` para lo que `apt` no resuelve. |

Los manejadores `custom` cubren lo que necesita pasos propios: `rustup`, `nvm`, `go.dev`, `uv`, `bun`, `deno`, `dotnet-install.sh`, el instalador de OpenCode, el de Ollama, los repositorios oficiales de Firefox, Brave y GitHub CLI, los tarballs de Neovim y Go, las herramientas de línea de comandos de Android, y los paquetes que piden confirmación (Docker, Wireshark, FFmpeg con códecs).

Antes de instalar, el script comprueba si la aplicación ya está presente y la salta. La comprobación se deduce del tipo, salvo que la entrada declare una explícita.

### Detalles que conviene conocer

- **No desinstala nada.** El script no borra navegadores ni paquetes. Los `.deb` oficiales se instalan vía `apt`, así que `sudo apt purge <paquete>` sigue funcionando.
- **El registro empieza al confirmar**, no antes. Los menús no se guardan en el archivo, solo la instalación.
- **Los PATH se modifican de forma idempotente.** Cada manejador añade sus líneas a `~/.bashrc` y `~/.profile` solo si no están ya.
- **`sudo` se pide una vez** al principio y se refresca solo mientras dura la instalación.
- **Cierra sesión tras Docker o Wireshark**, y abre una terminal nueva tras NVM, Rust, Go, Bun o Deno. El script te lo recuerda al terminar.

---

## Estructura del proyecto

```
QuickStart/
├── quick_start.sh              Punto de entrada: menú, CLI y orquestación
├── lib/
│   ├── ui.sh                     Colores, banners, mensajes y preguntas
│   ├── checks.sh                 Comprobaciones del sistema
│   ├── catalog.sh                Catálogo de aplicaciones y perfiles
│   ├── installers.sh             Motores de instalación y manejadores custom
│   ├── wifi.sh                   Detección e instalación del driver Wi-Fi
│   ├── themes.sh                 Tema e iconos (personalización)
│   └── removers.sh               Desinstalación de lo que sabe instalar
├── themes/
│   └── MacTahoe-Dark/            Tema GTK incluido, listo para instalar
├── tests/
│   ├── validar_catalogo.sh       Comprueba la integridad del catálogo
│   └── probar_menu.sh            Prueba la lógica de menús y selección
├── docs/
│   └── CONTRIBUTING.md           Cómo añadir apps y enviar cambios
├── README.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

---

## Añadir una aplicación

Añade **una línea** a `lib/catalog.sh`. Nada más.

```
id | categoría | tipo | argumento | nombre | descripción | comprobación
```

Por ejemplo, para Neovim:

```
neovim|Editores e IDEs|custom|neovim|Neovim|Editor modal moderno|
```

Si usas un tipo que necesita pasos propios, añade el manejador en `lib/installers.sh`:

```bash
custom_miapp_instalada() {
    command -v miapp >/dev/null 2>&1
}

custom_miapp() {
    irun "sudo apt install -y miapp"
}
```

Después valida el catálogo:

```bash
./tests/validar_catalogo.sh
```

Los detalles completos están en [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).

Si la app tiene un desinstalador propio, añádelo en `lib/removers.sh` con el nombre `custom_miapp_desinstalar`.

---

## Registro y diagnóstico

Toda la instalación se guarda en un archivo. Por defecto:

```
/tmp/quickstart-AAAAMMDD-HHMMSS.log
```

Puedes fijar la ruta:

```bash
./quick_start.sh --perfil backend --log ~/quickstart.log
```

Si algo falla, el informe final separa lo instalado, lo omitido y lo fallido, y el registro tiene el detalle completo de cada orden.

### Antes de reportar un problema

```bash
./quick_start.sh --perfil TU_PERFIL --simular
```

Si en simulación todo es correcto, el problema suele estar en la red o en los permisos de `sudo`.

---

## Contribuir

Las contribuciones son bienvenidas. Lee [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).

Antes de enviar cambios:

```bash
./tests/validar_catalogo.sh
bash -n quick_start.sh
```

Si tienes `shellcheck` instalado:

```bash
shellcheck quick_start.sh lib/*.sh tests/*.sh
```

---

## Licencia

MIT. Ver [LICENSE](LICENSE).

Las marcas y los nombres de los productos mencionados pertenecen a sus respectivos dueños. Este proyecto no está afiliado con Microsoft, Mozilla, Brave, JetBrains, Valve ni ninguna de las marcas que instala. Cada aplicación se descarga desde su fuente oficial en el momento de instalarse.
