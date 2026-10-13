#!/usr/bin/env bash

# ============================================================
#  QuickStart · lib/wifi.sh
# ============================================================
#  Detección del controlador Wi-Fi MediaTek MT7902 y, solo si el
#  hardware coincide, instalación del instalador oficial.
#
#  Si el equipo no lleva ese chip no se instala nada y ni siquiera
#  se menciona la opción: no tiene sentido ofrecer un driver que
#  no va a servir.
# ============================================================

# Repositorio con el instalador del driver MT7902.
WIFI_MT7902_REPO="https://github.com/SkimerPM/MediaTek-MT7902-Linux-Driver-Installer"
WIFI_MT7902_SCRIPT="instalar_wifi.sh"

# Identificación del chip. Se rellena en wifi_detectar.
WIFI_CHIP=""
WIFI_COMPATIBLE=0

# Extrae el identificador del controlador de red inalámbrico.
# Combina lspci, lsusb y /sys para no depender de una sola utilidad.
wifi_hardware() {
    if command -v lspci >/dev/null 2>&1; then
        lspci -nn 2>/dev/null | grep -iE 'network controller|wireless|wifi'
    fi

    if command -v lsusb >/dev/null 2>&1; then
        lsusb 2>/dev/null | grep -iE 'mediatek|wireless|wifi|802\.11'
    fi

    # Respaldo sin pciutils/usbutils: se leen los ids directamente de /sys.
    local dispositivo vendor device

    for dispositivo in /sys/bus/pci/devices/*; do
        [ -r "$dispositivo/vendor" ] || continue

        vendor="$(cat "$dispositivo/vendor" 2>/dev/null)"
        device="$(cat "$dispositivo/device" 2>/dev/null)"

        [ "$vendor" = "0x14c3" ] && printf 'PCI %s:%s\n' "${vendor#0x}" "${device#0x}"
    done
}

# Analiza el hardware y decide si el driver MT7902 aplica aquí.
wifi_detectar() {
    WIFI_CHIP=""
    WIFI_COMPATIBLE=0

    local hw
    hw="$(wifi_hardware)"

    # MT7902 aparece como 14c3:7902 (PCIe) o con el nombre literal.
    if printf '%s\n' "$hw" | grep -qiE 'mt7902|14c3:7902'; then
        WIFI_CHIP="MediaTek MT7902"
        WIFI_COMPATIBLE=1
        return 0
    fi

    # Otro MediaTek no gestionado por este instalador.
    if printf '%s\n' "$hw" | grep -qiE 'mediatek|14c3:'; then
        WIFI_CHIP="MediaTek (no MT7902)"
        return 1
    fi

    return 1
}

wifi_es_compatible() {
    [ "$WIFI_COMPATIBLE" = "1" ]
}

# Comprueba si el driver ya está cargado o compilado.
wifi_ya_instalado() {
    if lsmod 2>/dev/null | grep -qE '^mt79(02|21e?)\b'; then
        return 0
    fi

    [ -d "/lib/modules/$(uname -r)/updates/dkms" ] &&
        ls "/lib/modules/$(uname -r)/updates/dkms" 2>/dev/null | grep -qi mt79

    return 1
}

# Ofrece la instalación solo cuando el chip coincide.
# Devuelve 0 si se instaló (o ya estaba), 1 si el usuario dijo que no.
wifi_ofrecer() {
    wifi_detectar

    if ! wifi_es_compatible; then
        return 1
    fi

    ui_step "Controlador Wi-Fi"

    if wifi_ya_instalado; then
        ui_success "Driver Wi-Fi ($WIFI_CHIP) ya presente en el sistema."
        return 0
    fi

    ui_warning "Se detectó un controlador Wi-Fi que Ubuntu no trae: $WIFI_CHIP"
    ui_detail "Sin este driver es probable que no haya conexión inalámbrica."

    if ! ui_yes_no "¿Instalar el driver Wi-Fi $WIFI_CHIP?"; then
        ui_skip "Driver Wi-Fi omitido por decisión del usuario."
        return 1
    fi

    if wifi_instalar; then
        ui_success "Driver Wi-Fi $WIFI_CHIP instalado."
        ui_detail "Puede ser necesario reiniciar para que cargue el módulo."
        return 0
    fi

    ui_error "No se pudo instalar el driver Wi-Fi $WIFI_CHIP."
    ui_detail "Consulta el registro para ver el detalle."
    return 1
}

# Clona el repositorio del instalador y lo ejecuta.
wifi_instalar() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] clonar $WIFI_MT7902_REPO y ejecutar $WIFI_MT7902_SCRIPT"
        return 0
    fi

    if ! command -v git >/dev/null 2>&1; then
        ui_error "git es necesario para descargar el driver."
        return 1
    fi

    local destino
    destino="$(mktemp -d)/mt7902"

    if ! git clone --depth 1 "$WIFI_MT7902_REPO" "$destino" >/dev/null 2>&1; then
        ui_error "No se pudo clonar el repositorio del driver."
        return 1
    fi

    if [ ! -f "$destino/$WIFI_MT7902_SCRIPT" ]; then
        ui_error "El repositorio no contiene $WIFI_MT7902_SCRIPT."
        rm -rf "$(dirname "$destino")"
        return 1
    fi

    chmod +x "$destino/$WIFI_MT7902_SCRIPT"
    irun "sudo bash '$destino/$WIFI_MT7902_SCRIPT'"
    local estado=$?

    rm -rf "$(dirname "$destino")"
    return "$estado"
}
