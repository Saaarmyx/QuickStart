#!/usr/bin/env bash

# ============================================================
#  QuickStart · lib/themes.sh
# ============================================================
#  Personalización del escritorio: instala en el sistema el tema
#  incluido en themes/ y lo aplica.
#
#  Es opcional y nunca se ejecuta solo: el usuario lo pide desde
#  el menú de personalización o con --tema.
# ============================================================

TEMA_NOMBRE="MacTahoe-Dark"
TEMA_ORIGEN="$SCRIPT_DIR/themes/$TEMA_NOMBRE"
TEMA_DESTINO="$HOME/.themes"

# Packs complementarios de iconos y cursores que completan el aspecto.
# Se descargan solo si el usuario acepta; si falla, se queda el tema GTK.
ICONOS_URL="https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip"
CURSORES_URL="https://github.com/vinceliuice/WhiteSur-cursor/archive/refs/heads/master.zip"

# true si la sesión actual es GNOME (incluye Ubuntu y Unity).
tema_es_gnome() {
    case "${XDG_CURRENT_DESKTOP:-}" in
        *GNOME* | *gnome* | *Ubuntu* | *Unity*)
            return 0
            ;;
    esac

    # Respaldo: existe gnome-shell aunque no haya variable de sesión.
    command -v gsettings >/dev/null 2>&1
}

aplicar_gsettings() {
    local clave="$1"
    local valor="$2"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] gsettings set $clave $valor"
        return 0
    fi

    gsettings set "$clave" "$valor" 2>/dev/null || true
}

# Copia el tema incluido a ~/.themes para que lo vea el sistema.
tema_copiar() {
    if [ ! -d "$TEMA_ORIGEN" ]; then
        ui_error "No se encontró el tema en $TEMA_ORIGEN."
        return 1
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] copiar $TEMA_ORIGEN a $TEMA_DESTINO"
        return 0
    fi

    mkdir -p "$TEMA_DESTINO"
    rm -rf "${TEMA_DESTINO:?}/$TEMA_NOMBRE"
    cp -r "$TEMA_ORIGEN" "$TEMA_DESTINO/$TEMA_NOMBRE"

    # index.theme apunta a iconos y cursores que no vienen incluidos:
    # se limpian para que el escritorio no intente cargar fantasmas.
    if grep -q '^IconTheme=' "$TEMA_DESTINO/$TEMA_NOMBRE/index.theme" 2>/dev/null; then
        sed -i '/^IconTheme=/d;/^CursorTheme=/d' \
            "$TEMA_DESTINO/$TEMA_NOMBRE/index.theme"
    fi

    ui_success "Tema copiado a $TEMA_DESTINO/$TEMA_NOMBRE"
}

# Descarga un pack de GitHub y lo deja en ~/.icons.
tema_descargar_pack() {
    local url="$1"
    local nombre="$2"
    local destino="$HOME/.icons/$nombre"

    [ -d "$destino" ] && return 0

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] descargar $nombre desde $url"
        return 0
    fi

    local temporal
    temporal="$(mktemp -d)"

    ui_detail "Descargando $nombre..."

    if ! curl -fL --progress-bar -o "$temporal/pack.zip" "$url" >/dev/null 2>&1; then
        rm -rf "$temporal"
        return 1
    fi

    if ! unzip -q "$temporal/pack.zip" -d "$temporal" 2>/dev/null; then
        rm -rf "$temporal"
        return 1
    fi

    local origen
    origen="$(find "$temporal" -maxdepth 1 -mindepth 1 -type d | head -n 1)"

    [ -n "$origen" ] || {
        rm -rf "$temporal"
        return 1
    }

    mkdir -p "$HOME/.icons"
    rm -rf "$destino"
    mv "$origen" "$destino"
    rm -rf "$temporal"

    # Los temas de vinceliuice necesitan generarse una vez instalados.
    if [ -x "$destino/install.sh" ]; then
        (cd "$destino" && ./install.sh -t hicolor >/dev/null 2>&1) || true
    fi

    ui_success "Pack instalado en $destino"
}

# Aplica tema, iconos y cursor en la sesión GNOME actual.
tema_aplicar() {
    if ! tema_es_gnome; then
        ui_warning "Esta sesión no es GNOME: el tema queda instalado pero sin aplicar."
        ui_detail "Aplicalo desde los ajustes de tu escritorio."
        return 0
    fi

    ui_info "Aplicando el tema en la sesión actual..."

    aplicar_gsettings org.gnome.desktop.interface gtk-theme "$TEMA_NOMBRE"
    aplicar_gsettings org.gnome.desktop.interface color-scheme 'prefer-dark'
    aplicar_gsettings org.gnome.desktop.wm.preferences theme "$TEMA_NOMBRE"
    aplicar_gsettings org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:menu'

    if [ -d "$HOME/.icons/WhiteSur" ]; then
        aplicar_gsettings org.gnome.desktop.interface icon-theme 'WhiteSur'
    fi

    if [ -d "$HOME/.icons/WhiteSur-cursors" ]; then
        aplicar_gsettings org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
    fi

    ui_success "Tema aplicado."
    ui_detail "Cierra y abre sesión si alguna aplicación no lo refleja."
}

# Punto de entrada del menú de personalización.
tema_instalar() {
    ui_step "Personalización"

    if [ ! -d "$TEMA_ORIGEN" ]; then
        ui_error "No hay temas incluidos en este proyecto."
        return 1
    fi

    ui_info "Tema disponible: $TEMA_NOMBRE"
    ui_detail "Se copiará a ~/.themes y se aplicará en GNOME."
    ui_detail "Los iconos y cursores se descargan solo si lo aceptas."

    if ! ui_yes_no "¿Instalar y aplicar el tema $TEMA_NOMBRE?"; then
        ui_skip "Personalización omitida."
        return 0
    fi

    tema_copiar || return 1

    if ui_yes_no "¿Descargar iconos y cursores WhiteSur (necesita red)?"; then
        if ! command -v unzip >/dev/null 2>&1; then
            irun "sudo apt install -y unzip"
        fi

        tema_descargar_pack "$ICONOS_URL" "WhiteSur" || ui_warning "No se pudieron descargar los iconos."
        tema_descargar_pack "$CURSORES_URL" "WhiteSur-cursors" || ui_warning "No se pudo descargar el cursor."
    fi

    tema_aplicar

    if ! command -v gnome-tweaks >/dev/null 2>&1; then
        if ui_yes_no "¿Instalar gnome-tweaks para gestionar temas desde un panel?"; then
            irun "sudo apt install -y gnome-tweaks"
        fi
    fi

    ui_success "Personalización completada."
}

# Deshace lo anterior y vuelve al tema del sistema.
tema_quitar() {
    ui_step "Eliminar la personalización"

    if ! ui_yes_no "¿Quitar el tema $TEMA_NOMBRE y restaurar el del sistema?"; then
        return 0
    fi

    if tema_es_gnome; then
        local base
        base="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")"

        if [ "$base" = "$TEMA_NOMBRE" ]; then
            aplicar_gsettings org.gnome.desktop.interface gtk-theme 'Yaru'
            aplicar_gsettings org.gnome.desktop.interface color-scheme 'prefer-light'
            aplicar_gsettings org.gnome.desktop.wm.preferences theme 'Yaru'
            aplicar_gsettings org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
            aplicar_gsettings org.gnome.desktop.interface icon-theme 'Yaru'
            aplicar_gsettings org.gnome.desktop.interface cursor-theme 'Yaru'
        fi
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_detail "[simulación] borrar $TEMA_DESTINO/$TEMA_NOMBRE y los packs WhiteSur"
        return 0
    fi

    rm -rf "${TEMA_DESTINO:?}/$TEMA_NOMBRE"
    rm -rf "$HOME/.icons/WhiteSur" "$HOME/.icons/WhiteSur-cursors"

    ui_success "Personalización eliminada."
}
