#!/usr/bin/env bash

# ============================================================
#  QuickStart · tests/validar_catalogo.sh
# ============================================================
#  Comprueba la integridad del catálogo sin instalar nada.
#
#    ./tests/validar_catalogo.sh
#
#  Sale con código 0 si todo es correcto y con 1 si hay errores.
#  Ejecuta esto antes de abrir un pull request.
# ============================================================

set -uo pipefail

RAIZ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
. "$RAIZ/lib/ui.sh"
# shellcheck source=/dev/null
. "$RAIZ/lib/catalog.sh"
# shellcheck source=/dev/null
. "$RAIZ/lib/installers.sh"
# shellcheck source=/dev/null
. "$RAIZ/lib/checks.sh"

HOST_ARCH="amd64"
ERRORES=0

fallo() {
    ui_error "$1"
    ERRORES=$((ERRORES + 1))
}

ui_init_colors

# ------------------------------------------------------------
#  1. Sintaxis de todos los scripts
# ------------------------------------------------------------

ui_step "1. Sintaxis"

while IFS= read -r script; do
    if bash -n "$script" 2>/dev/null; then
        ui_success "$(basename "$script")"
    else
        fallo "Error de sintaxis en $script"
        bash -n "$script" 2>&1 | sed 's/^/          /'
    fi
done < <(find "$RAIZ" -name '*.sh' -not -path '*/.git/*' | sort)

# ------------------------------------------------------------
#  2. Estructura de las líneas del catálogo
# ------------------------------------------------------------

ui_step "2. Estructura del catálogo"

while IFS= read -r linea; do
    campos="$(printf '%s' "$linea" | awk -F'|' '{ print NF }')"
    id="$(printf '%s' "$linea" | cut -d'|' -f1)"

    if [ "$campos" -ne 7 ]; then
        fallo "'$id' tiene $campos campos y debe tener 7"
    fi

    if [ -z "$(catalog_field "$id" 4)" ]; then
        fallo "'$id' no tiene argumento"
    fi

    if [ -z "$(catalog_field "$id" 5)" ]; then
        fallo "'$id' no tiene nombre visible"
    fi
done <<<"$(catalog_lines)"

[ "$ERRORES" -eq 0 ] && ui_success "Estructura correcta en todas las líneas"

# ------------------------------------------------------------
#  3. Identificadores únicos y válidos
# ------------------------------------------------------------

ui_step "3. Identificadores"

duplicados="$(catalog_lines | cut -d'|' -f1 | sort | uniq -d)"

if [ -n "$duplicados" ]; then
    fallo "Identificadores duplicados: $duplicados"
else
    ui_success "No hay identificadores duplicados."
fi

while IFS= read -r id; do
    if ! printf '%s' "$id" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
        fallo "Identificador no válido: '$id' (solo minúsculas, números y guiones)"
    fi
done <<<"$(catalog_lines | cut -d'|' -f1)"

# ------------------------------------------------------------
#  4. Tipos de instalación
# ------------------------------------------------------------

ui_step "4. Tipos de instalación"

while IFS= read -r tipo; do
    case "$tipo" in
        apt | snap | flatpak | deb | ppa | custom)
            ui_success "Tipo '$tipo' válido."
            ;;
        *)
            fallo "Tipo desconocido: '$tipo'"
            ;;
    esac
done <<<"$(catalog_lines | cut -d'|' -f3 | sort -u)"

# ------------------------------------------------------------
#  5. Manejadores custom
# ------------------------------------------------------------

ui_step "5. Manejadores custom"

manejadores="$(catalog_lines | awk -F'|' '$3 == "custom" { print $4 }' | sort -u)"

while IFS= read -r manejador; do
    [ -n "$manejador" ] || continue

    if ! declare -f "custom_${manejador}" >/dev/null; then
        fallo "Falta la función custom_${manejador} en lib/installers.sh"
    fi

    if ! declare -f "custom_${manejador}_instalada" >/dev/null; then
        fallo "Falta la función custom_${manejador}_instalada en lib/installers.sh"
    fi
done <<<"$manejadores"

ui_success "$(printf '%s\n' "$manejadores" | wc -l | tr -d ' ') manejadores comprobados."

# ------------------------------------------------------------
#  6. Perfiles
# ------------------------------------------------------------

ui_step "6. Perfiles"

while IFS= read -r perfil; do
    if [ -z "$(profile_description "$perfil")" ]; then
        fallo "El perfil '$perfil' no tiene descripción"
    fi

    for id in $(profile_apps "$perfil"); do
        if ! catalog_exists "$id"; then
            fallo "El perfil '$perfil' referencia un id inexistente: '$id'"
        fi
    done

    ui_success "Perfil '$perfil' correcto."
done <<<"$(profiles_names)"

# ------------------------------------------------------------
#  Resumen
# ------------------------------------------------------------

echo
ui_step "Resumen"

ui_table "Aplicaciones" "$(catalog_count)"
ui_table "Categorías" "$(catalog_categories | wc -l | tr -d ' ')"
ui_table "Perfiles" "$(profiles_names | wc -l | tr -d ' ')"

echo

if [ "$ERRORES" -eq 0 ]; then
    ui_success "El catálogo es válido."
    exit 0
fi

ui_error "Se encontraron $ERRORES problemas."
exit 1
