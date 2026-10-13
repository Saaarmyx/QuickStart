#!/usr/bin/env bash

# ============================================================
#  QuickStart · lib/catalog.sh
# ============================================================
#  Catálogo maestro de aplicaciones y perfiles.
#
#  FORMATO DE CADA LÍNEA (separada por "|"):
#
#    id | categoría | tipo | argumento | nombre | descripción | comprobación
#
#  - id           Identificador único, en minúsculas y sin espacios.
#  - categoría    Grupo en el que aparece en el menú.
#  - tipo         apt | snap | flatpak | deb | ppa | custom
#  - argumento    Paquetes separados por espacio, nombre de snap,
#                 id de Flatpak, URL del .deb o manejador custom.
#  - comprobación Es opcional. Si se omite se deduce del tipo.
#                 Formatos: apt:a,b   snap:x   flatpak:x
#                            bin:cmd1,cmd2   path:/ruta
#
#  Para añadir una aplicación basta con añadir una línea nueva.
#  Ver docs/CONTRIBUTING.md para los detalles.
# ============================================================

CATALOG_RAW=$(cat <<'CATALOG_EOF'
# ------------------------------------------------------------------
# NAVEGADORES
# ------------------------------------------------------------------
zen|Navegadores|custom|zen|Zen Browser|Navegador rápido y privado basado en Firefox|
firefox|Navegadores|custom|firefox|Mozilla Firefox|Navegador desde el repositorio oficial de Mozilla|
chrome|Navegadores|deb|https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb|Google Chrome|Navegador de Google|
brave|Navegadores|custom|brave|Brave Browser|Navegador con bloqueador de anuncios integrado|

# ------------------------------------------------------------------
# LENGUAJES Y RUNTIMES
# ------------------------------------------------------------------
python|Lenguajes y runtimes|apt|python3 python3-pip python3-venv python3-dev python-is-python3|Python 3|Intérprete, pip y entornos virtuales|
pyenv|Lenguajes y runtimes|apt|pyenv|Pyenv|Gestor de versiones de Python|
uv|Lenguajes y runtimes|custom|uv|uv|Gestor de paquetes y proyectos Python written in Rust, muy rápido|
jupyter|Lenguajes y runtimes|apt|jupyter-notebook|Jupyter Notebook|Entorno de trabajo para notebooks Python|
node|Lenguajes y runtimes|custom|nvm|Node.js + NVM|Node.js con gestor de versiones (LTS por defecto)|
bun|Lenguajes y runtimes|custom|bun|Bun|Runtime JavaScript alternative con instalador propio|
deno|Lenguajes y runtimes|custom|deno|Deno|Runtime seguro para TypeScript y JavaScript|
rust|Lenguajes y runtimes|custom|rust|Rust + Cargo|Instalado mediante rustup, gestor oficial|
go|Lenguajes y runtimes|custom|go|Go|Lenguaje de Google, instalado desde el tarball oficial|
java|Lenguajes y runtimes|apt|default-jdk|OpenJDK|Java Development Kit|
php|Lenguajes y runtimes|apt|php-cli composer|PHP + Composer|Intérprete PHP y gestor de dependencias|
ruby|Lenguajes y runtimes|apt|ruby-full|Ruby|Intérprete completo de Ruby|
dotnet|Lenguajes y runtimes|custom|dotnet|.NET SDK|Runtime de Microsoft|
elixir|Lenguajes y runtimes|apt|elixir|Elixir + Erlang|Lenguaje funcional sobre BEAM|
rstats|Lenguajes y runtimes|apt|r-base r-cran-ggplot2|R + RStudio|Entorno de análisis estadístico|

# ------------------------------------------------------------------
# EDITORES E IDES
# ------------------------------------------------------------------
vscode|Editores e IDEs|custom|vscode|Visual Studio Code|Editor de código de Microsoft|
vscodium|Editores e IDEs|deb|https://github.com/VSCodium/vscodium/releases/latest/download/VSCodium-linux-x64.deb|VS Codium|Clone de VS Code sin telemetría|
zed|Editores e IDEs|deb|https://github.com/zed-industries/zed/releases/latest/download/Zed-linux-x86_64.deb|Zed|Editor rápido escrito en Rust|
sublime|Editores e IDEs|deb|https://download.sublimetext.com/sublime_text_latest_amd64.deb|Sublime Text|Editor de textos rápido|
jetbrains|Editores e IDEs|deb|https://download.jetbrains.com/toolbox/jetbrains-toolbox-latest-amd64.deb|JetBrains Toolbox|Gestor de IDEs de JetBrains|
android-studio|Editores e IDEs|custom|android-studio|Android Studio (cmdline tools)|Herramientas de línea de comandos para Android|
neovim|Editores e IDEs|custom|neovim|Neovim|Editor modal moderno, instalado desde el tarball oficial|
vim|Editores e IDEs|apt|vim neovim|Vim + Neovim|Editores modales de la familia vi|
emacs|Editores e IDEs|apt|emacs|Emacs|Editor clásico ampliable|

# ------------------------------------------------------------------
# CONTENEDORES Y DEVOPS
# ------------------------------------------------------------------
git|Contenedores y DevOps|apt|git|Git|Sistema de control de versiones|
docker|Contenedores y DevOps|custom|docker|Docker Engine + Compose|Motor de contenedores con plugin compose|
podman|Contenedores y DevOps|apt|podman|Podman|Contenedores sin demonio y sin root|
kubectl|Contenedores y DevOps|snap|kubectl|Kubectl|Cliente de Kubernetes|
helm|Contenedores y DevOps|snap|helm|Helm|Gestor de charts de Kubernetes|
minikube|Contenedores y DevOps|snap|minikube|Minikube|Kubernetes local para desarrollo|
ansible|Contenedores y DevOps|apt|ansible|Ansible|Automatización de infraestructura|
terraform|Contenedores y DevOps|ppa|ppa:hashicorp/terraform|Terraform|Infrastructura como código|
github-cli|Contenedores y DevOps|custom|github-cli|GitHub CLI (gh)|gh oficial de GitHub en tu terminal|
postman|Contenedores y DevOps|flatpak|com.getpostman.Postman|Postman|Cliente para probar APIs|
insomnia|Contenedores y DevOps|flatpak|com.insomnia.rest|Insomnia|Cliente REST alternativo|
dbeaver|Contenedores y DevOps|deb|https://github.com/dbeaver/dbeaver/releases/latest/download/dbeaver-ce_latest_amd64.deb|DBeaver CE|Cliente universal de bases de datos|
lazygit|Contenedores y DevOps|apt|lazygit|LazyGit|Interfaz de terminal para Git|
github-desktop|Contenedores y DevOps|flatpak|io.github.phracker.MahGit|GitHub Desktop|Cliente gráfico de Git|

# ------------------------------------------------------------------
# BASES DE DATOS
# ------------------------------------------------------------------
postgres-client|Bases de datos|apt|postgresql-client|PostgreSQL (cliente)|psql y herramientas de PostgreSQL|
mysql-client|Bases de datos|apt|mysql-client|MySQL / MariaDB (cliente)|Cliente de MySQL|
redis-tools|Bases de datos|apt|redis-tools|Redis (herramientas)|redis-cli y utilidades|
sqlite|Bases de datos|apt|sqlite3|SQLite|Motor de base de datos ligero|

# ------------------------------------------------------------------
# SOCIAL Y COMUNICACIÓN
# ------------------------------------------------------------------
discord|Social y comunicación|deb|https://discord.com/api/download?platform=linux&format=deb|Discord|Voice, chat y comunidad|
telegram|Social y comunicación|snap|telegram-desktop|Telegram Desktop|Mensajería rápida y cifrada|
signal|Social y comunicación|flatpak|org.signal.Signal|Signal|Mensajería privada de código abierto|
slack|Social y comunicación|flatpak|com.slack.Slack|Slack|Mensajería para equipos|
element|Social y comunicación|flatpak|org.matrix.element|Element|Cliente de Matrix y rooms federadas|
whatsapp|Social y comunicación|flatpak|com.whatsapp.WhatsApp|WhatsApp Desktop|Mensajería de WhatsApp|
zoom|Social y comunicación|deb|https://zoom.us/client/latest/zoom_amd64.deb|Zoom|Videollamadas|
teams|Social y comunicación|deb|https://packages.microsoft.com/repos/teams/pool/main/t/teams-for-linux-deb/teams-for-linux-latest_amd64.deb|Microsoft Teams|Videollamadas de Microsoft|

# ------------------------------------------------------------------
# PRODUCTIVIDAD
# ------------------------------------------------------------------
libreoffice|Productividad|apt|libreoffice libreoffice-l10n-es|LibreOffice|Ofimática completa en español|
obsidian|Productividad|snap|obsidian|Obsidian|Notas en Markdown con enlaces|
joplin|Productividad|snap|joplin|Joplin|Notas y tareas sincronizables|
bitwarden|Productividad|flatpak|org.bitwarden.desktop|Bitwarden|Gestor de contraseñas|
keepassxc|Productividad|apt|keepassxc|KeePassXC|Gestor de contraseñas local|
synaptic|Productividad|apt|synaptic|Synaptic|Gestor gráfico de paquetes|
gnome-tweaks|Productividad|apt|gnome-tweaks|Ajustes de GNOME|Opciones avanzadas del escritorio|
gnome-extensions|Productividad|apt|gnome-shell-extension-prefs|Extensiones de GNOME|Gestor de extensiones del shell|
fonts|Productividad|apt|fonts-firacode fonts-jetbrains-mono fonts-hack fonts-noto-color-emoji|Fuentes para desarrollo|Tipografías monoespaciadas y emoji|
timeshift|Productividad|apt|timeshift|Timeshift|Instantes del sistema mediante rsync|

# ------------------------------------------------------------------
# MULTIMEDIA Y DISEÑO
# ------------------------------------------------------------------
spotify|Multimedia y diseño|snap|spotify|Spotify|Música y podcasts|
vlc|Multimedia y diseño|apt|vlc|VLC|Reproductor de vídeo y audio|
celluloid|Multimedia y diseño|apt|celluloid mpv|Celluloid + MPV|Reproductor minimalista basado en mpv|
ffmpeg|Multimedia y diseño|custom|ffmpeg|FFmpeg + códecs|Codificación de vídeo/audio y códecs patentados|
audacity|Multimedia y diseño|apt|audacity|Audacity|Edición de audio|
obs-studio|Multimedia y diseño|apt|obs-studio|OBS Studio|Grabación de pantalla y streaming|
kdenlive|Multimedia y diseño|apt|kdenlive|Kdenlive|Editor de vídeo multipista|
handbrake|Multimedia y diseño|apt|handbrake|HandBrake|Compresión de vídeo|
gimp|Multimedia y diseño|apt|gimp|GIMP|Edición de imágenes|
inkscape|Multimedia y diseño|apt|inkscape|Inkscape|Ilustración vectorial|
krita|Multimedia y diseño|apt|krita|Krita|Dibujo digital|
blender|Multimedia y diseño|apt|blender|Blender|Modelado 3D, animación y render|
yt-dlp|Multimedia y diseño|apt|yt-dlp|yt-dlp|Descargador de vídeo y audio|

# ------------------------------------------------------------------
# GAMING
# ------------------------------------------------------------------
steam|Gaming|apt|steam-installer|Steam|Válvula y su biblioteca de juegos|
lutris|Gaming|apt|lutris|Lutris|Ejecuta juegos de Windows y otras plataformas|
heroic|Gaming|flatpak|com.heroicgameslauncher.hgl|Heroic Games Launcher|Gestor de juegos de Epic y GOG|
gamescope|Gaming|apt|gamescope|Gamescope|Compositor para jugar en modo consola|
protonup-qt|Gaming|apt|protonup-qt|ProtonUp-Qt|Gestor de versiones de Proton|
mangohud|Gaming|apt|mangohud|MangoHud|Sensor de FPS y overlay en los juegos|
mangohud-ui|Gaming|apt|mangohud-ui|Control de MangoHud|Interfaz gráfica para configurar el overlay|

# ------------------------------------------------------------------
# TERMINAL Y UTILIDADES
# ------------------------------------------------------------------
btop|Terminal y utilidades|apt|btop btop++|btop++|Monitor de recursos moderno|
htop|Terminal y utilidades|apt|htop|htop|Monitor de procesos|
fastfetch|Terminal y utilidades|apt|fastfetch|fastfetch|Información del sistema, alternativa a neofetch|
neofetch|Terminal y utilidades|apt|neofetch|neofetch|Información del sistema con ascii art|
bat|Terminal y utilidades|apt|bat batcat|bat|Cat con resaltado de sintaxis|
eza|Terminal y utilidades|apt|eza|eza|Ls moderno con iconos|
ripgrep|Terminal y utilidades|apt|ripgrep fd-find|ripgrep + fd|Búsqueda de texto y de archivos, muy rápida|
fzf|Terminal y utilidades|apt|fzf|fzf|Selector interactivo por shell|
tldr|Terminal y utilidades|apt|tldr|tldr|Ejemplos de comandos en español e inglés|
jq-yq|Terminal y utilidades|apt|jq yq|jq + yq|Procesamiento de JSON y YAML|
shellcheck|Terminal y utilidades|apt|shellcheck|ShellCheck|Análisis estático de scripts bash|
starship|Terminal y utilidades|apt|starship|Starship|Prompt moderno y rápido para shells|
zsh-fish|Terminal y utilidades|apt|zsh fish|Zsh + Fish|Shells alternativos con resaltado|
terminals|Terminal y utilidades|apt|alacritty kitty tilix|Terminales|alacritty, kitty y tilix|
tmux|Terminal y utilidades|apt|tmux|tmux|Multiplexor de terminal|
archivadores|Terminal y utilidades|apt|p7zip-full p7zip-rar unrar zip unzip|Archivadores|7-Zip, RAR, ZIP y UNZIP|
imagenmagick|Terminal y utilidades|apt|imagemagick|ImageMagick|Conversión y edición de imágenes por CLI|
pandoc|Terminal y utilidades|apt|pandoc|Pandoc|Conversor de documentos entre formatos|

# ------------------------------------------------------------------
# SEGURIDAD Y RED
# ------------------------------------------------------------------
openssh|Red y seguridad|apt|openssh-client|OpenSSH (cliente)|Acceso remoto seguro|
ufw-firewall|Red y seguridad|apt|ufw fail2ban|UFW + Fail2ban|Cortafuegos y protección por fuerza bruta|
wireshark|Red y seguridad|custom|wireshark|Wireshark|Análisis de tráfico de red|
nmap|Red y seguridad|apt|nmap|Nmap|Escaneo de puertos y servicios|
red-cli|Red y seguridad|apt|net-tools iputils-ping dnsutils traceroute pciutils usbutils|Herramientas de red|ping, dns, traceroute, pci y usb|
speedtest|Red y seguridad|apt|iperf3 speedtest-cli|Medidor de velocidad|Iperf3 y test de descarga|

# ------------------------------------------------------------------
# IA Y ASISTENTES
# ------------------------------------------------------------------
opencode|IA y asistentes|custom|opencode|OpenCode|Agente de programación en terminal|
claude-code|IA y asistentes|custom|claude-code|Claude Code|Asistente de programación de Anthropic|
ollama|IA y asistentes|custom|ollama|Ollama|Ejecuta modelos de lenguaje en local|
chatgpt|IA y asistentes|flatpak|com.openai.chatgpt|ChatGPT|Cliente oficial de OpenAI|
CATALOG_EOF
)

# ------------------------------------------------------------------
#  PERFILES
# ------------------------------------------------------------------
#  Formato: nombre | descripción | ids separados por espacio

PROFILES_RAW=$(cat <<'PROFILES_EOF'
minimal|Lo esencial del día a día|git btop fastfetch ripgrep jq-yq
frontend|Desarrollo web frontend|git node bun python vscode vscodium zen postman insomnia yt-dlp btop jq-yq
backend|Desarrollo backend|git node python docker postgres-client mysql-client redis-tools vscode postman lazygit btop
data|Ciencia de datos|git python uv jupyter rstats postgres-client dbeaver vscode btop
devops|Infraestructura y DevOps|git docker podman kubectl helm minikube ansible terraform github-cli lazygit btop ripgrep
mobile|Desarrollo móvil|git node python jupyter android-studio vscode insomnia btop
multimedia|Creación audiovisual|ffmpeg vlc celluloid audacity obs-studio kdenlive handbrake inkscape gimp krita yt-dlp
gamedev|Ejecución de juegos|steam lutris heroic gamescope protonup-qt mangohud mangohud-ui btop
social|Social y comunicación|discord telegram signal slack element whatsapp spotify bitwarden
privacidad|Entorno privado y ligero|zen signal bitwarden keepassxc ufw-firewall btop fastfetch
PROFILES_EOF
)

# ------------------------------------------------------------------
#  API DEL CATÁLOGO
# ------------------------------------------------------------------

# Devuelve todas las líneas de datos (sin comentarios ni vacías).
catalog_lines() {
    printf '%s\n' "$CATALOG_RAW" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$'
}

catalog_count() {
    catalog_lines | wc -l | tr -d ' '
}

# Número de campo (1..7) de una entrada del catálogo.
catalog_field() {
    local id="$1"
    local numero="$2"
    local linea

    linea="$(catalog_lines | awk -F'|' -v id="$id" '$1 == id { print; exit }')"

    if [ -z "$linea" ]; then
        return 1
    fi

    printf '%s' "$linea" | cut -d'|' -f"$numero"
}

# Comprueba si un identificador existe en el catálogo.
catalog_exists() {
    catalog_field "$1" 2 >/dev/null 2>&1
}

# Lista las categorías en el orden en que aparecen.
catalog_categories() {
    catalog_lines | cut -d'|' -f2 | awk '!visto[$0]++'
}

# Lista los identificadores de una categoría, en orden de catálogo.
catalog_apps_in() {
    local categoria="$1"

    catalog_lines | awk -F'|' -v cat="$categoria" '$2 == cat { print $1 }'
}

# Nombre legible de la categoría a partir de un id.
catalog_category_of() {
    catalog_field "$1" 2
}

# Tipo legible para mostrar en el menú.
catalog_type_label() {
    case "$1" in
        apt) echo "apt" ;;
        snap) echo "snap" ;;
        flatpak) echo "flatpak" ;;
        deb) echo "deb" ;;
        ppa) echo "ppa" ;;
        custom) echo "instalador" ;;
        *) echo "$1" ;;
    esac
}

# ---------------------------------------------------------------
#  Perfiles
# ---------------------------------------------------------------

profiles_lines() {
    printf '%s\n' "$PROFILES_RAW" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$'
}

profiles_names() {
    profiles_lines | cut -d'|' -f1
}

# Las líneas de PROFILES_RAW tienen tres campos:
#   nombre | descripción | ids separados por espacio
profile_description() {
    local nombre="$1"

    profiles_lines | awk -F'|' -v n="$nombre" '$1 == n { print $2; exit }'
}

profile_apps() {
    local nombre="$1"

    profiles_lines | awk -F'|' -v n="$nombre" '$1 == n { print $3; exit }'
}
