#!/usr/bin/env bash

# ============================================================
#  QuickStart · lib/removers.sh
# ============================================================
#  Desinstalación de lo que el catálogo sabe instalar.
#
#  Se usa desde el menú de desinstalación o con --desinstalar.
#  Solo se ofrece quitar lo que aparece en el catálogo: el resto
#  del sistema no se toca.
# ============================================================

# .deb descargados de terceros: no hay paquete conocido en el
# repositorio, así que se indica a mano el nombre que deja dpkg.
DEB_PAQUETES=(
    "chrome=google-chrome-stable"
    "code-insiders=code-insiders"
    "postman=postman"
    "dbeaver=dbeaver-ce"
)

DEB_PAQUETE_DE() {
    local id="$1"
    local entrada

    for entrada in "${DEB_PAQUETES[@]}"; do
        [ "${entrada%%=*}" = "$id" ] && {
            printf '%s' "${entrada#*=}"
            return 0
        }
    done

    return 1
}

# Paquetes que nunca se purgan aunque el catálogo los liste.
# Quitarlos deja el sistema inservible (python3, por ejemplo, lo
# usan apt, el actualizador de release y media distro).
PAQUETES_PROTEGIDOS=(
    python3 python python-is-python3 libpython3-stdlib
    bash coreutils sudo systemd dbus base-files libc6
    apt dpkg libapt-pkg6.0 software-properties-common
    gnome-shell mutter gdm3 ubuntu-desktop
    network-manager firmware-linux
)

# Devuelve 0 si el paquete está en la lista de protección.
es_paquete_protegido() {
    local paquete="$1"
    local protegido

    for protegido in "${PAQUETES_PROTEGIDOS[@]}"; do
        [ "$protegido" = "$paquete" ] && return 0
    done

    return 1
}

# Devuelve el paquete apt que hay que purgar para un id del catálogo.
remover_paquete_apt() {
    local id="$1"
    local tipo argumento paquete

    tipo="$(catalog_field "$id" 3)"
    argumento="$(catalog_field "$id" 4)"

    case "$tipo" in
        apt)
            # Múltiples paquetes separados por espacio: se purga el primero,
            # que es el paquete principal del que suelen colgar los demás.
            printf '%s' "${argumento%% *}"
            ;;
        deb)
            DEB_PAQUETE_DE "$id"
            ;;
        ppa)
            paquete="${argumento#ppa:}"
            printf '%s' "${paquete##*/}"
            ;;
        *)
            return 1
            ;;
    esac
}

# Comprueba si una app del catálogo está instalada en el sistema.
remover_instalada() {
    local id="$1"

    app_ya_instalada "$id"
}

# Quita la app indicada del catálogo. Devuelve 0 si se quitó.
remover_app() {
    local id="$1"
    local tipo argumento nombre

    tipo="$(catalog_field "$id" 3)"
    argumento="$(catalog_field "$id" 4)"
    nombre="$(catalog_field "$id" 5)"

    ui_info "Desinstalando: $nombre ${DIM}($id)${NC}"

    case "$tipo" in
        apt | deb | ppa)
            local paquete
            paquete="$(remover_paquete_apt "$id")"

            if [ -z "$paquete" ]; then
                ui_error "No se conoce el paquete apt de '$id'."
                return 1
            fi

            if es_paquete_protegido "$paquete"; then
                ui_warning "'$nombre' usa el paquete base '$paquete'."
                ui_detail "Quitarlo dejaría el sistema inservible, así que no se purga."
                ui_detail "Si de verdad lo necesitas: sudo apt purge $paquete"
                return 1
            fi

            irun "sudo apt purge -y ${paquete}"
            ;;
        snap)
            irun "sudo snap remove ${argumento}"
            ;;
        flatpak)
            irun "sudo flatpak uninstall -y --noninteractive ${argumento}"
            ;;
        custom)
            remover_custom "$id" "$argumento"
            ;;
        *)
            ui_error "Tipo desconocido para '$id': $tipo"
            return 1
            ;;
    esac
}

# Despacho a los manejadores propios de cada app sin gestor estándar.
remover_custom() {
    local id="$1"
    local manejador="custom_${id}_desinstalar"

    if declare -F "$manejador" >/dev/null 2>&1; then
        "$manejador"
        return $?
    fi

    ui_warning " '$id' no tiene un desinstalador automático."
    ui_detail "Quítala a mano o con el gestor que uses para ella."
    return 1
}

# ------------------------------------------------------------
#  Desinstaladores propios
# ------------------------------------------------------------

custom_zen_desinstalar() {
    rm -rf "$HOME/.local/opt/zen"
    rm -f "$HOME/.local/bin/zen-browser"
    rm -f "$HOME/.local/share/applications/zen-browser.desktop"
    rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/zen-browser.png"

    ui_success "Zen Browser eliminado."
}

custom_firefox_desinstalar() {
    irun "sudo apt purge -y firefox"
    irun "sudo rm -f /etc/apt/sources.list.d/mozilla.list /etc/apt/keyrings/packages.mozilla.org.apt.gpg"
    irun "sudo apt update -qq"
}

custom_brave_desinstalar() {
    irun "sudo apt purge -y brave-browser"
    irun "sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list /etc/apt/keyrings/brave-browser-archive-keyring.gpg"
    irun "sudo apt update -qq"
}

custom_vscode_desinstalar() {
    irun "sudo apt purge -y code"
    irun "sudo rm -f /etc/apt/sources.list.d/vscode.list /etc/apt/keyrings/microsoft.gpg"
    irun "sudo apt update -qq"
}

custom_nvm_desinstalar() {
    if [ -s "$ruta_nvm/nvm.sh" ]; then
        # shellcheck disable=SC1091
        . "$ruta_nvm/nvm.sh"
        irun "nvm uninstall --lts"
    fi

    rm -rf "$ruta_nvm"
    ui_success "NVM y las versiones de Node eliminadas."
}

custom_rust_desinstalar() {
    if [ -x "$ruta_cargo/bin/rustup" ]; then
        irun "$ruta_cargo/bin/rustup self uninstall -y"
    fi

    rm -rf "$ruta_cargo"
    ui_success "Rust eliminado."
}

custom_go_desinstalar() {
    irun "sudo rm -rf /usr/local/go"
    ui_success "Go eliminado."
}

custom_uv_desinstalar() {
    if command -v uv >/dev/null 2>&1; then
        irun "uv tool uninstall uv"
    fi

    rm -rf "$HOME/.local/share/uv" "$HOME/.cargo/bin/uv"
    ui_success "uv eliminado."
}

custom_bun_desinstalar() {
    rm -rf "$ruta_bun"
    ui_success "Bun eliminado."
}

custom_deno_desinstalar() {
    rm -rf "$ruta_deno"
    ui_success "Deno eliminado."
}

custom_dotnet_desinstalar() {
    rm -rf "$ruta_dotnet"
    ui_success ".NET SDK eliminado."
}

custom_neovim_desinstalar() {
    irun "sudo rm -rf /usr/local/nvim /usr/local/bin/nvim"
    ui_success "Neovim eliminado."
}

custom_android-studio_desinstalar() {
    rm -rf "$HOME/Android"
    ui_success "Herramientas de Android eliminadas."
}

custom_opencode_desinstalar() {
    if command -v npm >/dev/null 2>&1; then
        irun "npm uninstall -g opencode-ai"
    fi

    rm -rf "$HOME/.opencode" "$HOME/.local/bin/opencode"
    ui_success "OpenCode eliminado."
}

custom_claude-code_desinstalar() {
    if command -v npm >/dev/null 2>&1; then
        irun "npm uninstall -g @anthropic-ai/claude-code"
    fi

    ui_success "Claude Code eliminado."
}

custom_ollama_desinstalar() {
    irun "sudo rm -f /usr/local/bin/ollama"
    rm -rf "$HOME/.ollama"
    ui_success "Ollama eliminado."
}

custom_docker_desinstalar() {
    irun "sudo apt purge -y docker.io docker-compose-v2"
    ui_success "Docker eliminado."
}

custom_ffmpeg_desinstalar() {
    irun "sudo apt purge -y ffmpeg"
}

custom_wireshark_desinstalar() {
    irun "sudo apt purge -y wireshark"
    irun "sudo userdel -G wireshark ${USER}"
}
