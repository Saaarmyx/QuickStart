#!/usr/bin/env bash

# ============================================================
#  InicioRapido · lib/checks.sh
# ============================================================
#  Comprobaciones del sistema: distribución, arquitectura,
#  privilegios, red y disponibilidad de herramientas.
# ============================================================

# Distribución y versión detectadas. Se rellenan en checks_system.
UBUNTU_PRETTY_NAME=""
UBUNTU_VERSION_ID=""
UBUNTU_CODENAME=""
HOST_ARCH=""

checks_system() {
    if [ ! -f /etc/os-release ]; then
        ui_error "No se pudo detectar la distribución del sistema."
        return 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    UBUNTU_PRETTY_NAME="${PRETTY_NAME:-desconocida}"
    UBUNTU_VERSION_ID="${VERSION_ID:-}"
    UBUNTU_CODENAME="${VERSION_CODENAME:-desconocido}"
    HOST_ARCH="$(dpkg --print-architecture 2>/dev/null || echo desconocido)"

    if [ "${ID:-}" != "ubuntu" ]; then
        ui_error "Este instalador solamente funciona en Ubuntu."
        ui_detail "Sistema detectado: ${ID:-desconocido}"
        return 2
    fi

    ui_success "Sistema detectado: $UBUNTU_PRETTY_NAME"
    ui_detail  "Versión: $UBUNTU_VERSION_ID  ·  Alias: $UBUNTU_CODENAME  ·  Arquitectura: $HOST_ARCH"

    # Aviso, no error: el script funciona en otras LTS.
    case "$UBUNTU_VERSION_ID" in
        24.04 | 26.04)
            ui_detail "Versión objetivo soportada."
            ;;
        *)
            ui_warning "Esta versión no es el objetivo principal del proyecto."
            ui_detail "Probado en Ubuntu 24.04 LTS y 26.04 LTS."
            ui_detail "El menú deshabilitará los instaladores que no funcionen aquí."
            ;;
    esac

    return 0
}

checks_arch() {
    case "$HOST_ARCH" in
        amd64)
            return 0
            ;;
        arm64)
            ui_warning "Arquitectura arm64: algunas apps .deb de terceros no existen."
            ui_detail "Se omitirán automáticamente las descargas exclusivas de amd64."
            return 0
            ;;
        *)
            ui_warning "Arquitectura no soportada: $HOST_ARCH"
            return 0
            ;;
    esac
}

checks_root() {
    if [ "$(id -u)" -eq 0 ]; then
        ui_error "No ejecutes el script como root."
        ui_detail "Ejecútalo con tu usuario normal: el script usa sudo internamente."
        return 1
    fi

    return 0
}

checks_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        ui_error "sudo no está instalado en el sistema."
        return 1
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] no se solicitan privilegios."
        return 0
    fi

    ui_info "Solicitando privilegios de administrador..."
    if ! sudo -v; then
        ui_error "No se pudieron validar los privilegios de sudo."
        return 1
    fi

    ui_success "Privilegios de administrador validados."
    return 0
}

checks_network() {
    if ! command -v curl >/dev/null 2>&1; then
        return 0
    fi

    if ! curl -fsSI --max-time 10 https://archive.ubuntu.com/ >/dev/null 2>&1; then
        ui_error "No hay conexión a Internet."
        ui_detail "Sin red no se pueden descargar índices ni instaladores."
        return 1
    fi

    ui_success "Conexión a Internet disponible."
    return 0
}

# curl y wget son la base de todo el instalador: si faltan se
# instalan con apt antes de seguir.
checks_download_tools() {
    local faltan=()

    command -v curl >/dev/null 2>&1 || faltan+=("curl")
    command -v wget >/dev/null 2>&1 || faltan+=("wget")

    if [ "${#faltan[@]}" -eq 0 ]; then
        return 0
    fi

    ui_warning "Faltan herramientas de descarga: ${faltan[*]}"
    ui_info "Instalando: ${faltan[*]}"

    sudo apt update -qq
    sudo apt install -y "${faltan[@]}"

    return 0
}

# dpkg puede quedarse bloqueado si otro gestor de paquetes corrió
# a medias. Lo reparamos antes de instalar nada.
checks_repair_apt() {
    ui_info "Reparando el estado de los paquetes..."

    sudo dpkg --configure -a >/dev/null 2>&1 || true
    sudo apt --fix-broken install -y >/dev/null 2>&1 || true

    ui_success "Estado de los paquetes correcto."
    return 0
}

checks_apt_ready() {
    checks_root || return 1
    checks_arch || return 1
    checks_download_tools || return 1
    checks_sudo || return 1
    checks_network || return 1

    return 0
}
