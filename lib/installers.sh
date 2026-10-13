#!/usr/bin/env bash

# ============================================================
#  QuickStart · lib/installers.sh
# ============================================================
#  Motores de instalación. Cada tipo del catálogo tiene su
#  función correspondente, además de los manejadores
#  "custom" que requieren pasos que apt no puede resolver.
# ============================================================

# ------------------------------------------------------------
#  Utilidades de bajo nivel
# ------------------------------------------------------------

# Ejecuta una orden, o la muestra si estamos en modo simulación.
# Se usa bash -c para poder componer tuberías y redirecciones.
irun() {
    local orden="$1"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] $orden"
        return 0
    fi

    ui_detail "\$ $orden"
    bash -c "$orden"
}

# Añade una línea a ~/.bashrc y a ~/.profile si no existe.
agregar_al_perfil() {
    local linea="$1"
    local archivo

    for archivo in "$HOME/.bashrc" "$HOME/.profile"; do
        [ -f "$archivo" ] || continue

        if ! grep -qF "$linea" "$archivo" 2>/dev/null; then
            if [ "${DRY_RUN:-0}" = "1" ]; then
                ui_detail "[simulación] añadir a $archivo: $linea"
            else
                printf '\n%s\n' "$linea" >>"$archivo"
                ui_detail "PATH actualizado en $archivo"
            fi
        fi
    done
}

# Rutas de instalación que usan varios manejadores.
ruta_nvm="$HOME/.nvm"
ruta_cargo="$HOME/.cargo"
ruta_bun="$HOME/.bun"
ruta_deno="$HOME/.deno"
ruta_dotnet="$HOME/.dotnet"
ruta_go="/usr/local/go"

NVM_VERSION="v0.40.3"
NVM_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"

# ------------------------------------------------------------
#  Comprobación de instalación previa
# ------------------------------------------------------------

# Comprueba si TODOS los paquetes apt indicados están instalados.
apt_ya_instalado() {
    local paquete

    for paquete in "$@"; do
        if ! dpkg-query -W -f='${Status}' "$paquete" 2>/dev/null |
            grep -q "install ok installed"; then
            return 1
        fi
    done

    return 0
}

snap_ya_instalado() {
    snap list "$1" >/dev/null 2>&1
}

flatpak_ya_instalado() {
    command -v flatpak >/dev/null 2>&1 && flatpak info "$1" >/dev/null 2>&1
}

# Punto de entrada único: recibe el id del catálogo y decide.
app_ya_instalada() {
    local id="$1"
    local tipo
    local argumento
    local comprobacion

    tipo="$(catalog_field "$id" 3)"
    argumento="$(catalog_field "$id" 4)"
    comprobacion="$(catalog_field "$id" 7)"

    # Si el catálogo define una comprobación explícita, manda.
    if [ -n "$comprobacion" ]; then
        case "$comprobacion" in
            apt:*)
                local lista="${comprobacion#apt:}"
                local paquete
                local alguno_falta=1

                for paquete in ${lista//,/ }; do
                    if apt_ya_instalado "$paquete"; then
                        alguno_falta=0
                    fi
                done

                return "$alguno_falta"
                ;;
            snap:*)
                snap_ya_instalado "${comprobacion#snap:}"
                ;;
            flatpak:*)
                flatpak_ya_instalado "${comprobacion#flatpak:}"
                ;;
            bin:*)
                local lista="${comprobacion#bin:}"
                local comando
                local alguno_existe=1

                for comando in ${lista//,/ }; do
                    if command -v "$comando" >/dev/null 2>&1; then
                        alguno_existe=0
                        break
                    fi
                done

                return "$alguno_existe"
                ;;
            path:*)
                [ -e "${comprobacion#path:}" ]
                ;;
            *)
                return 1
                ;;
        esac
    fi

    # Si no hay comprobación explícita, se deduce del tipo.
    case "$tipo" in
        apt)
            # shellcheck disable=SC2086
            apt_ya_instalado $argumento
            ;;
        snap)
            snap_ya_instalado "$argumento"
            ;;
        flatpak)
            flatpak_ya_instalado "$argumento"
            ;;
        ppa)
            apt_ya_instalado "$argumento"
            ;;
        custom)
            "custom_${argumento}_instalada"
            ;;
        deb)
            # No hay forma fiable de saberlo: se reinstala.
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
#  Motores genéricos
# ------------------------------------------------------------

instalar_apt() {
    local id="$1"
    # shellcheck disable=SC2086
    local paquetes="$(catalog_field "$id" 4)"

    irun "sudo apt install -y ${paquetes}"
}

instalar_snap() {
    local id="$1"
    local nombre="$(catalog_field "$id" 4)"

    asegurar_snapd
    irun "sudo snap install ${nombre}"
}

instalar_flatpak() {
    local id="$1"
    local app_id="$(catalog_field "$id" 4)"

    asegurar_flatpak
    irun "sudo flatpak install -y --noninteractive flathub ${app_id}"
}

instalar_deb() {
    local id="$1"
    local url="$(catalog_field "$id" 4)"

    if [ "$HOST_ARCH" != "amd64" ]; then
        ui_warning "Omitida en $HOST_ARCH: el paquete .deb solo existe para amd64."
        return 2
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] descargar $url y ejecutar apt install"
        return 0
    fi

    local temporal
    temporal="$(mktemp -d)/$(basename "$url" | cut -d'?' -f1)"

    ui_detail "Descargando $(basename "$url")..."

    if ! curl -fL --progress-bar -o "$temporal" "$url"; then
        ui_error "No se pudo descargar: $url"
        rm -rf "$(dirname "$temporal")"
        return 1
    fi

    if ! irun "sudo apt install -y ${temporal}"; then
        rm -rf "$(dirname "$temporal")"
        return 1
    fi

    rm -rf "$(dirname "$temporal")"
    return 0
}

instalar_ppa() {
    local id="$1"
    local ppa="$(catalog_field "$id" 4)"
    local paquete="${ppa#ppa:}"

    irun "sudo apt install -y software-properties-common"
    irun "sudo add-apt-repository -y ${paquete}"
    irun "sudo apt update -qq"
    irun "sudo apt install -y ${paquete##*/}"
}

# Comprueba si el catálogo necesita snap o flatpak en la selección.
# Recibe una lista de ids separados por espacios, así que se
# recorren palabra a palabra y no línea a línea.
seleccion_necesita_snap() {
    local id

    for id in $1; do
        [ "$(catalog_field "$id" 3)" = "snap" ] && return 0
    done

    return 1
}

seleccion_necesita_flatpak() {
    local id

    for id in $1; do
        [ "$(catalog_field "$id" 3)" = "flatpak" ] && return 0
    done

    return 1
}

asegurar_snapd() {
    if command -v snap >/dev/null 2>&1; then
        return 0
    fi

    ui_detail "Instalando snapd..."
    irun "sudo apt install -y snapd"
    irun "sudo systemctl enable --now snapd.socket"
}

asegurar_flatpak() {
    if ! command -v flatpak >/dev/null 2>&1; then
        ui_detail "Instalando flatpak..."
        irun "sudo apt install -y flatpak"
    fi

    if ! flatpak remotes 2>/dev/null | grep -q flathub; then
        ui_detail "Añadiendo el repositorio de Flathub..."
        irun "sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
        irun "sudo flatpak update"
    fi
}

# ------------------------------------------------------------
#  Manejadores custom
# ------------------------------------------------------------

instalar_custom() {
    local id="$1"
    local manejador="$(catalog_field "$id" 4)"

    "custom_${manejador}"
}

# ---- Zen Browser --------------------------------------------
custom_zen_instalada() {
    [ -x "$HOME/.local/bin/zen-browser" ]
}

custom_zen() {
    local dir="$HOME/.local/opt/zen"
    local lanzador="$HOME/.local/bin/zen-browser"
    local escritorio="$HOME/.local/share/applications/zen-browser.desktop"
    local appimage

    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] descargar AppImage de Zen y crear lanzador"
        return 0
    fi

    appimage="$(mktemp)/zen.AppImage"

    if ! curl -fL --progress-bar -o "$appimage" \
        "https://github.com/zen-browser/desktop/releases/latest/download/zen-x86_64.AppImage"; then
        ui_error "No se pudo descargar Zen Browser."
        return 1
    fi

    rm -rf "$dir"
    mkdir -p "$dir"
    chmod +x "$appimage"
    mv "$appimage" "$dir/zen.AppImage"

    cat >"$lanzador" <<EOF
#!/usr/bin/env bash
exec "$dir/zen.AppImage" "\$@"
EOF
    chmod +x "$lanzador"

    cat >"$escritorio" <<EOF
[Desktop Entry]
Name=Zen Browser
Comment=Un navegador rápido y privado
Exec=$lanzador %U
Icon=$dir/zen.AppImage
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=zen
EOF

    irun "update-desktop-database $HOME/.local/share/applications"
}

# ---- Firefox -----------------------------------------------
custom_firefox_instalada() {
    command -v firefox >/dev/null 2>&1 || apt_ya_instalado firefox
}

custom_firefox() {
    irun "sudo install -d -m 0755 /etc/apt/keyrings"
    irun "curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg | sudo tee /etc/apt/keyrings/packages.mozilla.org.apt.gpg > /dev/null"
    irun "printf 'deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.apt.gpg] https://packages.mozilla.org/apt mozilla main\n' | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null"
    irun "sudo apt update -qq"
    irun "sudo apt install -y firefox"
}

# ---- Brave -------------------------------------------------
custom_brave_instalada() {
    command -v brave-browser >/dev/null 2>&1 || apt_ya_instalado brave-browser
}

custom_brave() {
    irun "sudo install -d -m 0755 /etc/apt/keyrings"
    irun "curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | sudo tee /etc/apt/keyrings/brave-browser-archive-keyring.gpg > /dev/null"
    irun "printf 'deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main\n' | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null"
    irun "sudo apt update -qq"
    irun "sudo apt install -y brave-browser"
}

# ---- NVM / Node.js -----------------------------------------
custom_nvm_instalada() {
    [ -s "$ruta_nvm/nvm.sh" ]
}

custom_nvm() {
    if [ ! -s "$ruta_nvm/nvm.sh" ]; then
        irun "curl -o- ${NVM_URL} | bash"
    fi

    irun "export NVM_DIR='${ruta_nvm}' && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm install --lts && nvm alias default 'lts/*' && node --version && npm --version"

    agregar_al_perfil 'export NVM_DIR="$HOME/.nvm"'
    agregar_al_perfil '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
}

# ---- Rust --------------------------------------------------
custom_rust_instalada() {
    [ -x "$ruta_cargo/bin/rustc" ] || command -v rustc >/dev/null 2>&1
}

custom_rust() {
    irun "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    irun "'${ruta_cargo}/bin/rustc' --version && '${ruta_cargo}/bin/cargo' --version"
    agregar_al_perfil '. "$HOME/.cargo/env"'
}

# ---- Go ----------------------------------------------------
custom_go_instalada() {
    [ -x "$ruta_go/bin/go" ] || command -v go >/dev/null 2>&1
}

custom_go() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] consultar go.dev/VERSION, descargar el tarball e instalar en $ruta_go"
        return 0
    fi

    local version
    version="$(curl -fsSL https://go.dev/VERSION?m=text | head -n 1)"

    if [ -z "$version" ]; then
        ui_error "No se pudo consultar la última versión de Go."
        return 1
    fi

    local arquitectura="amd64"
    [ "$HOST_ARCH" = "arm64" ] && arquitectura="arm64"

    local archivo
    archivo="$(mktemp)/go.tar.gz"

    ui_detail "Descargando $version..."

    if ! curl -fL --progress-bar -o "$archivo" "https://go.dev/dl/${version}.linux-${arquitectura}.tar.gz"; then
        ui_error "No se pudo descargar Go."
        return 1
    fi

    rm -rf "$ruta_go"
    irun "sudo tar -C /usr/local -xzf ${archivo}"

    irun "printf 'export PATH=\$PATH:/usr/local/go/bin\n' | sudo tee /etc/profile.d/go.sh"
    agregar_al_perfil 'export PATH="$PATH:/usr/local/go/bin"'

    ui_success "Go $version instalado."
}

# ---- uv ----------------------------------------------------
custom_uv_instalada() {
    command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ]
}

custom_uv() {
    irun "curl -LsSf https://astral.sh/uv/install.sh | sh"
    agregar_al_perfil 'export PATH="$HOME/.local/bin:$PATH"'
}

# ---- Bun ---------------------------------------------------
custom_bun_instalada() {
    [ -x "$ruta_bun/bin/bun" ] || command -v bun >/dev/null 2>&1
}

custom_bun() {
    irun "curl -fsSL https://bun.sh/install | bash"
    agregar_al_perfil 'export BUN_INSTALL="$HOME/.bun"'
    agregar_al_perfil 'export PATH="$BUN_INSTALL/bin:$PATH"'
}

# ---- Deno --------------------------------------------------
custom_deno_instalada() {
    [ -x "$ruta_deno/bin/deno" ] || command -v deno >/dev/null 2>&1
}

custom_deno() {
    irun "curl -fsSL https://deno.land/install.sh | sh"
    agregar_al_perfil 'export DENO_INSTALL="$HOME/.deno"'
    agregar_al_perfil 'export PATH="$DENO_INSTALL/bin:$PATH"'
}

# ---- .NET SDK ---------------------------------------------
custom_dotnet_instalada() {
    command -v dotnet >/dev/null 2>&1 || [ -x "$ruta_dotnet/dotnet" ]
}

custom_dotnet() {
    irun "curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel LTS"
    agregar_al_perfil 'export DOTNET_ROOT="$HOME/.dotnet"'
    agregar_al_perfil 'export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"'
}

# ---- GitHub CLI -------------------------------------------
custom_github-cli_instalada() {
    command -v gh >/dev/null 2>&1
}

custom_github-cli() {
    irun "sudo install -d -m 0755 /etc/apt/keyrings"
    irun "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null"
    irun "printf 'deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    irun "sudo apt update -qq"
    irun "sudo apt install -y gh"
}

# ---- Neovim -----------------------------------------------
custom_neovim_instalada() {
    command -v nvim >/dev/null 2>&1
}

custom_neovim() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] descargar el tarball de Neovim a /usr/local"
        return 0
    fi

    local arquitectura="x86_64"
    [ "$HOST_ARCH" = "arm64" ] && arquitectura="arm64"

    local archivo
    archivo="$(mktemp)/nvim.tar.gz"

    if ! curl -fL --progress-bar -o "$archivo" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arquitectura}.tar.gz"; then
        ui_error "No se pudo descargar Neovim."
        return 1
    fi

    irun "sudo rm -rf /usr/local/nvim && sudo tar -C /usr/local -xzf ${archivo}"
    irun "sudo ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim"

    ui_success "Neovim instalado."
}

# ---- Android Studio (command line tools) -------------------
custom_android-studio_instalada() {
    [ -d "$HOME/Android/cmdline-tools/latest" ]
}

custom_android-studio() {
    local raiz="$HOME/Android"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] descargar commandlinetools en $raiz/cmdline-tools/latest"
        return 0
    fi

    local archivo
    archivo="$(mktemp)/cmdline-tools.zip"

    if ! curl -fL --progress-bar -o "$archivo" \
        "https://dl.google.com/android/repository/commandlinetools-linux-latest.zip"; then
        ui_error "No se pudieron descargar las herramientas de línea de comandos."
        return 1
    fi

    rm -rf "$raiz/cmdline-tools"
    mkdir -p "$raiz/cmdline-tools"

    irun "unzip -q ${archivo} -d ${raiz}/cmdline-tools"
    irun "mv ${raiz}/cmdline-tools/cmdline-tools ${raiz}/cmdline-tools/latest"

    agregar_al_perfil "export ANDROID_HOME='${raiz}'"
    agregar_al_perfil 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"'

    ui_success "Herramientas de Android instaladas en $raiz."
    ui_detail "Ejecuta 'sdkmanager --licenses' para aceptar las licencias."
}

# ---- OpenCode ---------------------------------------------
custom_opencode_instalada() {
    command -v opencode >/dev/null 2>&1 || [ -x "$HOME/.opencode/bin/opencode" ]
}

custom_opencode() {
    irun "curl -fsSL https://opencode.ai/v2/install | bash"
    agregar_al_perfil 'export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"'
}

# ---- Claude Code ------------------------------------------
custom_claude-code_instalada() {
    command -v claude >/dev/null 2>&1
}

custom_claude-code() {
    if ! command -v npm >/dev/null 2>&1; then
        ui_error "Claude Code necesita Node.js y npm."
        ui_detail "Instala antes la opción 'Node.js + NVM'."
        return 1
    fi

    irun "npm install -g @anthropic-ai/claude-code"
}

# ---- Ollama -----------------------------------------------
custom_ollama_instalada() {
    command -v ollama >/dev/null 2>&1
}

custom_ollama() {
    irun "curl -fsSL https://ollama.com/install.sh | sh"
}

# ---- Docker ------------------------------------------------
custom_docker_instalada() {
    command -v docker >/dev/null 2>&1
}

custom_docker() {
    irun "sudo apt install -y docker.io docker-compose-v2"
    irun "sudo systemctl enable --now docker"
    irun "sudo usermod -aG docker ${USER}"

    ui_warning "Tu usuario se añadió al grupo docker."
    ui_detail "Cierra la sesión y vuelve a entrar para que surta efecto."
}

# ---- FFmpeg + códecs --------------------------------------
custom_ffmpeg_instalada() {
    command -v ffmpeg >/dev/null 2>&1
}

custom_ffmpeg() {
    irun "sudo env DEBIAN_FRONTEND=noninteractive apt install -y ffmpeg"
    irun "sudo env DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-restricted-extras ttf-mscorefonts-installer"
}

# ---- Wireshark --------------------------------------------
custom_wireshark_instalada() {
    command -v wireshark >/dev/null 2>&1
}

custom_wireshark() {
    # Preselecciona la pregunta de permisos para que no se bloquee.
    irun "echo 'wireshark-common/install-setuid boolean true' | sudo debconf-set-selections"
    irun "echo 'wireshark-common/non-root boolean false' | sudo debconf-set-selections"
    irun "sudo env DEBIAN_FRONTEND=noninteractive apt install -y wireshark"

    if [ "${DRY_RUN:-0}" != "1" ]; then
        irun "sudo usermod -aG wireshark ${USER}"
        ui_warning "Tu usuario se añadió al grupo wireshark."
        ui_detail "Cierra la sesión y vuelve a entrar para capturar sin sudo."
    fi
}

# ------------------------------------------------------------
#  Despachador
# ------------------------------------------------------------

instalar_app() {
    local id="$1"
    local tipo

    tipo="$(catalog_field "$id" 3)"

    case "$tipo" in
        apt) instalar_apt "$id" ;;
        snap) instalar_snap "$id" ;;
        flatpak) instalar_flatpak "$id" ;;
        deb) instalar_deb "$id" ;;
        ppa) instalar_ppa "$id" ;;
        custom) instalar_custom "$id" ;;
        *)
            ui_error "Tipo desconocido para '$id': $tipo"
            return 1
            ;;
    esac
}
