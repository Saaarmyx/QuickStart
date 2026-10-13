#!/usr/bin/env bash

# ============================================================
#  QuickStart · lib/ui.sh
# ============================================================
#  Interfaz de usuario: colores, banners, mensajes, preguntas
#  y utilidades de entrada por teclado.
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Desactiva los colores cuando la salida no es una terminal o
# cuando el usuario define NO_COLOR (estándar de la industria).
ui_init_colors() {
    if [ ! -t 1 ] || [ -n "${NO_COLOR:-}" ]; then
        GREEN=''
        YELLOW=''
        RED=''
        BLUE=''
        CYAN=''
        MAGENTA=''
        BOLD=''
        DIM=''
        NC=''
    fi
}

ui_banner() {
    local titulo="$1"
    local version="$2"

    clear 2>/dev/null || true

    echo -e "${CYAN}"
    echo "============================================================"
    printf ' %-56s\n' "$titulo"
    printf ' %-56s\n' "versión $version"
    echo "============================================================"
    echo -e "${NC}"
}

ui_step() {
    echo
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}============================================================${NC}"
}

ui_substep() {
    echo
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
}

ui_success() {
    printf '%b\n' "  ${GREEN}[OK]    $1${NC}"
}

ui_warning() {
    printf '%b\n' "  ${YELLOW}[AVISO] $1${NC}"
}

ui_error() {
    printf '%b\n' "  ${RED}[ERROR] $1${NC}" >&2
}

ui_info() {
    printf '%b\n' "  ${BLUE}[INFO]  $1${NC}"
}

# Imprime un comando sin interpretar sus secuencias de escape:
# las órdenes contienen \n literales que deben verse tal cual.
ui_detail() {
    printf '%b\n' "          ${DIM}${1}${NC}"
}

ui_skip() {
    printf '%b\n' "  ${DIM}[OMITE] $1${NC}"
}

ui_pause() {
    local mensaje="${1:-Pulsa ENTER para continuar...}"

    if [ ! -t 0 ]; then
        return 0
    fi

    echo
    read -rp "  ${YELLOW}${mensaje}${NC}" _unused_pause
    unset _unused_pause
}

# Pregunta de sí/no. Acepta S/s/Si/SI/sí y N/n/No/NO.
# Si ASSUME_YES=1 responde siempre que sí (útil para scripts y CI).
ui_yes_no() {
    local pregunta="$1"
    local respuesta

    if [ "${ASSUME_YES:-0}" = "1" ]; then
        ui_detail "Confirmación automática: sí -> $pregunta"
        return 0
    fi

    while true; do
        read -rp "  ${BOLD}${pregunta}${NC} [S/n]: " respuesta
        respuesta="${respuesta:-s}"

        case "$respuesta" in
            s | S | si | SI | sí | Sí | SÍ)
                return 0
                ;;
            n | N | no | NO | No)
                return 1
                ;;
            *)
                ui_error "Responde S o N."
                ;;
        esac
    done
}

# Muestra una tabla sencilla de dos columnas.
ui_table() {
    local izquierda="$1"
    local derecha="$2"

    printf '  %-34s %s\n' "$izquierda" "$derecha"
}

# Cuenta cuántos argumentos de $2 están contenidos en $1.
ui_contiene() {
    local lista="$1"
    local valor="$2"
    local item

    for item in $lista; do
        if [ "$item" = "$valor" ]; then
            return 0
        fi
    done

    return 1
}
