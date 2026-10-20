#!/usr/bin/env bash

# ============================================================
#  QuickStart
#  Instalador interactivo de aplicaciones para Ubuntu
# ============================================================
#  Uso:
#    ./quick_start.sh                 menú interactivo
#    ./quick_start.sh --perfil devops perfil predefinido
#    ./quick_start.sh --instalar node,rust,python
#    ./quick_start.sh --ayuda
#
#  Licencia: MIT. Ver LICENSE.
# ============================================================

set -uo pipefail

VERSION="1.0.0"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for libreria in ui checks catalog installers wifi themes removers; do
    if [ ! -f "$LIB_DIR/$libreria.sh" ]; then
        printf 'ERROR: no se encontró %s\n' "$LIB_DIR/$libreria.sh" >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    . "$LIB_DIR/$libreria.sh"
done

# ------------------------------------------------------------
#  Estado global
# ------------------------------------------------------------

SELECCION=()
SIN_MENU=0
ASSUME_YES=0
DRY_RUN=0
LISTAR_SOLO=0
MODO_DESINSTALAR=0
MODO_TEMA=0
LOG_FILE="${LOG_FILE:-/tmp/quickstart-$(date +%Y%m%d-%H%M%S).log}"

INSTALADOS=()
FALLIDOS=()
OMITIDOS=()
DESINSTALADOS=()
DESINSTALADOS_FALLIDOS=()

# ------------------------------------------------------------
#  Uso
# ------------------------------------------------------------

mostrar_ayuda() {
    cat <<EOF
QuickStart $VERSION · instalador de aplicaciones para Ubuntu

USO
  ./quick_start.sh [opciones]

OPCIONES
  --instalar LISTA      Instala los ids indicados separados por comas.
                        Ejemplo: --instalar node,rust,vscode
  --perfil NOMBRE       Aplica un perfil. Usa --listar-perfiles para verlos.
  --categoria NOMBRE    Selecciona una categoría completa (admite comas).
  --todos               Selecciona todo el catálogo.
  --sin-menu            No muestra menús: instala directamente lo indicado.
  --si, --yes           No pide confirmación final.
  --simular, --dry-run  Muestra qué se haría sin instalar nada.
  --listar              Lista el catálogo completo y termina.
  --listar-perfiles     Lista los perfiles disponibles y termina.
  --desinstalar         Entra al modo de desinstalación de apps.
  --tema                Instala y aplica el tema incluido (GNOME).
  --log RUTA            Guarda el registro en la ruta indicada.
  --no-color            Desactiva los colores.
  --ayuda, -h           Muestra esta ayuda.

VARIABLES DE ENTORNO
  ASSUME_YES=1         Equivale a --si.
  NO_COLOR=1           Equivale a --no-color.
  LOG_FILE=RUTA        Ruta predeterminada del registro.

DESINSTALACIÓN
  Purga los navegadores detectados antes de instalar. Las apps
  antiguas no se tocan: usa 'sudo apt purge' si las necesitas quitar.

EJEMPLOS
  ./quick_start.sh
  ./quick_start.sh --perfil data --si
  ./quick_start.sh --instalar node,python,docker --simular
EOF
}

listar_catalogo() {
    local categoria_actual=""
    local id nombre tipo descripcion

    ui_banner "Catálogo de aplicaciones" "$VERSION"

    while IFS='|' read -r id _categoria tipo _arg nombre descripcion _check; do
        [ -n "$id" ] || continue

        if [ "$_categoria" != "$categoria_actual" ]; then
            categoria_actual="$_categoria"
            echo
            echo -e "${YELLOW}  ${categoria_actual}${NC}"
        fi

        ui_table "$id" "$(catalog_type_label "$tipo") · $nombre"
        ui_detail "$descripcion"
    done <<<"$(catalog_lines)"

    echo
    ui_info "Total: $(catalog_count) aplicaciones."
    echo
}

listar_perfiles() {
    local nombre descripcion apps

    ui_banner "Perfiles disponibles" "$VERSION"

    while IFS='|' read -r nombre descripcion apps; do
        [ -n "$nombre" ] || continue

        echo
        echo -e "${GREEN}  ${nombre}${NC}"
        ui_detail "$descripcion"
        ui_detail "$apps"
    done <<<"$(profiles_lines)"

    echo
    ui_detail "Uso: ./quick_start.sh --perfil <nombre>"
    echo
}

# ------------------------------------------------------------
#  Manejo de la selección
# ------------------------------------------------------------

esta_seleccionado() {
    local id="$1"
    local item

    for item in ${SELECCION[@]+"${SELECCION[@]}"}; do
        [ "$item" = "$id" ] && return 0
    done

    return 1
}

agregar_seleccion() {
    local id="$1"

    esta_seleccionado "$id" || SELECCION+=("$id")
}

quitar_seleccion() {
    local id="$1"
    local nueva=()
    local item

    for item in ${SELECCION[@]+"${SELECCION[@]}"}; do
        [ "$item" = "$id" ] || nueva+=("$item")
    done

    if [ "${#nueva[@]}" -eq 0 ]; then
        SELECCION=()
    else
        SELECCION=("${nueva[@]}")
    fi
}

alternar_seleccion() {
    local id="$1"

    if esta_seleccionado "$id"; then
        quitar_seleccion "$id"
        return 1
    fi

    agregar_seleccion "$id"
    return 0
}

contar_en_categoria() {
    local categoria="$1"
    local total=0
    local id

    while IFS= read -r id; do
        [ -n "$id" ] || continue
        esta_seleccionado "$id" && total=$((total + 1))
    done <<<"$(catalog_apps_in "$categoria")"

    echo "$total"
}

total_seleccion() {
    echo "${#SELECCION[@]}"
}

# Marca todas las apps de una categoría.
seleccionar_categoria() {
    local categoria="$1"
    local id

    while IFS= read -r id; do
        [ -n "$id" ] || continue
        agregar_seleccion "$id"
    done <<<"$(catalog_apps_in "$categoria")"
}

# ------------------------------------------------------------
#  Menús
# ------------------------------------------------------------

menu_categoria() {
    local categoria="$1"
    local -a apps
    local entrada
    local opcion
    local i
    local total
    local id
    local nombre
    local -a opciones

    mapfile -t apps < <(catalog_apps_in "$categoria")
    total="${#apps[@]}"

    while true; do
        clear 2>/dev/null || true

        ui_banner "$categoria" "$VERSION"

        ui_info "$total aplicaciones en esta categoría."
        ui_detail "Introduce números para marcar o desmarcar."
        ui_detail "Comandos: todos · ninguno · v (volver)"
        echo

        for i in "${!apps[@]}"; do
            id="${apps[$i]}"
            nombre="$(catalog_field "$id" 5)"

            local marca="[ ]"
            local tipo_texto
            esta_seleccionado "$id" && marca="[x]"
            tipo_texto="$(catalog_type_label "$(catalog_field "$id" 3)")"

            printf '  %-4s %2d) %-26s %b\n' \
                "$marca" "$((i + 1))" "$nombre" "${DIM}${tipo_texto}${NC}"
        done

        echo
        ui_table "Seleccionadas en total" "$(total_seleccion)"

        if ! read -rp "  ${BOLD}Selección:${NC} " entrada; then
            return 0
        fi

        [ -z "$entrada" ] && continue

        case "$entrada" in
            v | V | volver)
                return 0
                ;;
            todos)
                for i in "${!apps[@]}"; do
                    agregar_seleccion "${apps[$i]}"
                done
                ui_success "Todas las aplicaciones de la categoría seleccionadas."
                ;;
            ninguno)
                for i in "${!apps[@]}"; do
                    quitar_seleccion "${apps[$i]}"
                done
                ui_skip "Selección de la categoría vaciada."
                ;;
            *)
                # Acepta "1 3" y también "1,3".
                read -ra opciones <<<"${entrada//,/ }"

                for opcion in "${opciones[@]}"; do
                    if ! [[ "$opcion" =~ ^[0-9]+$ ]] ||
                        [ "$opcion" -lt 1 ] ||
                        [ "$opcion" -gt "$total" ]; then
                        ui_error "Opción no válida: $opcion"
                        continue
                    fi

                    if alternar_seleccion "${apps[$((opcion - 1))]}"; then
                        ui_success "Añadida: $(catalog_field "${apps[$((opcion - 1))]}" 5)"
                    else
                        ui_skip "Quitada: $(catalog_field "${apps[$((opcion - 1))]}" 5)"
                    fi
                done
                ;;
        esac
    done
}

# Menú de desinstalación: lista lo del catálogo que está instalado.
menu_desinstalar() {
    local -a instaladas=()
    local id nombre tipo

    while IFS= read -r id; do
        [ -n "$id" ] || continue

        if remover_instalada "$id"; then
            instaladas+=("$id")
        fi
    done <<<"$(catalog_lines | cut -d'|' -f1)"

    if [ "${#instaladas[@]}" -eq 0 ]; then
        ui_warning "No hay aplicaciones del catálogo instaladas."
        ui_detail "No hay nada que quitar desde aquí."
        return 0
    fi

    local entrada opcion i total="${#instaladas[@]}"
    local -a opciones

    while true; do
        clear 2>/dev/null || true

        ui_banner "Desinstalar aplicaciones" "$VERSION"

        ui_info "Aplicaciones del catálogo instaladas: $total"
        ui_detail "Introduce números para seleccionar. Comandos: v (volver)"
        echo

        for i in "${!instaladas[@]}"; do
            id="${instaladas[$i]}"
            nombre="$(catalog_field "$id" 5)"
            tipo="$(catalog_type_label "$(catalog_field "$id" 3)")"

            printf '  %-4s %2d) %-26s %b\n' "[ ]" "$((i + 1))" "$nombre" "${DIM}${tipo}${NC}"
        done

        echo
        read -rp "  ${BOLD}Selección:${NC} " entrada || return 0

        [ -z "$entrada" ] && continue

        case "$entrada" in
            v | V | volver)
                return 0
                ;;
            *)
                read -ra opciones <<<"${entrada//,/ }"
                local -a elegidas=()

                for opcion in "${opciones[@]}"; do
                    if ! [[ "$opcion" =~ ^[0-9]+$ ]] ||
                        [ "$opcion" -lt 1 ] ||
                        [ "$opcion" -gt "$total" ]; then
                        ui_error "Opción no válida: $opcion"
                        continue
                    fi

                    elegidas+=("${instaladas[$((opcion - 1))]}")
                done

                [ "${#elegidas[@]}" -eq 0 ] && continue

                echo
                ui_step "Confirmación"
                for id in "${elegidas[@]}"; do
                    ui_detail "- $(catalog_field "$id" 5)"
                done

                if ! ui_yes_no "¿Desinstalar ${#elegidas[@]} aplicación(es)?"; then
                    ui_skip "Desinstalación cancelada."
                    ui_pause
                    return 0
                fi

                exec > >(tee -a "$LOG_FILE") 2>&1

                DESINSTALADOS=()
                DESINSTALADOS_FALLIDOS=()

                for id in "${elegidas[@]}"; do
                    if remover_app "$id"; then
                        DESINSTALADOS+=("$id")
                    else
                        DESINSTALADOS_FALLIDOS+=("$id")
                    fi
                done

                ui_step "Informe de desinstalación"
                [ "${#DESINSTALADOS[@]}" -gt 0 ] &&
                    ui_success "Desinstaladas: ${DESINSTALADOS[*]}"
                [ "${#DESINSTALADOS_FALLIDOS[@]}" -gt 0 ] &&
                    ui_warning "Sin desinstalar: ${DESINSTALADOS_FALLIDOS[*]}"
                ui_detail "Registro: $LOG_FILE"

                ui_pause
                return 0
                ;;
        esac
    done
}

# Paso previo a todo: git y, si el hardware lo pide, el driver Wi-Fi.
instalar_base() {
    ui_step "Base del sistema"

    # git es lo primero: sin él no se pueden clonar drivers ni repos.
    if command -v git >/dev/null 2>&1; then
        ui_success "git ya está instalado."
    else
        ui_info "Instalando git..."
        irun "sudo apt install -y git"
    fi

    # El driver Wi-Fi solo aparece si el chip coincide.
    wifi_ofrecer
}

menu_principal() {
    local categorias
    local entrada
    local opcion
    local i
    local categoria

    mapfile -t categorias < <(catalog_categories)

    while true; do
        clear 2>/dev/null || true

        ui_banner "QuickStart · instalador de aplicaciones" "$VERSION"
        ui_detail "Sistema: ${UBUNTU_PRETTY_NAME:-desconocido} · $HOST_ARCH"
        echo

        for i in "${!categorias[@]}"; do
            categoria="${categorias[$i]}"
            local marca
            marca="$(contar_en_categoria "$categoria")"

            printf '  %2d) %-26s %b\n' \
                "$((i + 1))" "$categoria" \
                "${GREEN}($marca)${NC}"
        done

        echo
        echo -e "  ${BOLD}P)  Perfiles rápidos${NC}"
        echo -e "  ${BOLD}T)  Personalización: tema e iconos${NC}"
        echo -e "  ${BOLD}D)  Desinstalar aplicaciones${NC}"
        echo -e "  ${BOLD}C)  Catálogo completo${NC}"
        echo -e "  ${BOLD}0)  Continuar con la instalación${NC}"
        echo
        ui_table "Seleccionadas" "$(total_seleccion)"

        if ! read -rp "  ${BOLD}Opción:${NC} " entrada; then
            entrada="0"
        fi

        [ -z "$entrada" ] && continue

        case "$entrada" in
            0 | s | S)
                return 0
                ;;
            p | P)
                menu_perfiles
                ;;
            t | T)
                tema_instalar
                ui_pause
                ;;
            d | D)
                menu_desinstalar
                ;;
            c | C)
                listar_catalogo
                ui_pause
                ;;
            *)
                if [[ "$entrada" =~ ^[0-9]+$ ]] &&
                    [ "$entrada" -ge 1 ] &&
                    [ "$entrada" -le "${#categorias[@]}" ]; then
                    menu_categoria "${categorias[$((entrada - 1))]}"
                else
                    ui_error "Opción no válida: $entrada"
                    sleep 1
                fi
                ;;
        esac
    done
}

menu_perfiles() {
    local nombres
    local entrada
    local nombre

    mapfile -t nombres < <(profiles_names)

    while true; do
        clear 2>/dev/null || true

        ui_banner "Perfiles rápidos" "$VERSION"
        ui_detail "Cada perfil es un atajo a un grupo de apps."
        ui_detail "Se acumulan con lo que ya tengas seleccionado."
        echo

        local i
        for i in "${!nombres[@]}"; do
            nombre="${nombres[$i]}"
            printf '  %2d) %-14s %s\n' \
                "$((i + 1))" "$nombre" \
                "$(profile_description "$nombre")"
        done

        echo
        echo -e "  ${BOLD}0)  Volver${NC}"

        if ! read -rp "  ${BOLD}Perfil:${NC} " entrada; then
            return 0
        fi

        [ -z "$entrada" ] && continue

        case "$entrada" in
            0 | v | V)
                return 0
                ;;
            *)
                if [[ "$entrada" =~ ^[0-9]+$ ]] &&
                    [ "$entrada" -ge 1 ] &&
                    [ "$entrada" -le "${#nombres[@]}" ]; then
                    aplicar_perfil "${nombres[$((entrada - 1))]}"
                else
                    ui_error "Opción no válida: $entrada"
                fi
                ;;
        esac
    done
}

# ------------------------------------------------------------
#  Perfiles y CLI
# ------------------------------------------------------------

cargar_perfil() {
    local nombre="$1"
    local apps
    local id
    local validos=0
    local -a descartados=()

    if [ -z "$(profile_apps "$nombre")" ]; then
        ui_error "Perfil desconocido: $nombre"
        ui_detail "Usa --listar-perfiles para ver los disponibles."
        return 1
    fi

    apps="$(profile_apps "$nombre")"

    for id in $apps; do
        if catalog_exists "$id"; then
            agregar_seleccion "$id"
            validos=$((validos + 1))
        else
            descartados+=("$id")
        fi
    done

    ui_success "Perfil '$nombre': $validos aplicaciones añadidas."
    ui_detail "$apps"

    if [ "${#descartados[@]}" -gt 0 ]; then
        ui_warning "Ids ausentes del catálogo: ${descartados[*]}"
    fi

    return 0
}

aplicar_perfil() {
    cargar_perfil "$1"
    ui_pause
    return 0
}

aplicar_perfil_silencioso() {
    cargar_perfil "$1"
    return 0
}

seleccionar_todo() {
    local id

    while IFS= read -r id; do
        [ -n "$id" ] || continue
        agregar_seleccion "$id"
    done <<<"$(catalog_lines | cut -d'|' -f1)"
}

# Aplica --instalar con una lista separada por comas o espacios.
seleccionar_por_lista() {
    local lista="$1"
    local contexto="$2"
    local id
    local problemas=0

    for id in ${lista//,/ }; do
        id="${id// /}"

        if [ -z "$id" ]; then
            continue
        fi

        if catalog_exists "$id"; then
            agregar_seleccion "$id"
        else
            ui_error "$contexto: '$id' no existe en el catálogo."
            problemas=$((problemas + 1))
        fi
    done

    return "$problemas"
}

# ------------------------------------------------------------
#  Resumen previo
# ------------------------------------------------------------

mostrar_resumen() {
    local categorias
    local categoria
    local id
    local alguna=0
    local cuenta

    categorias="$(catalog_lines |
        awk -F'|' '{ print $2 }' |
        awk '!visto[$0]++')"

    ui_step "Resumen de la selección"

    while IFS= read -r categoria; do
        [ -n "$categoria" ] || continue

        cuenta=0

        while IFS= read -r id; do
            [ -n "$id" ] || continue

            if esta_seleccionado "$id"; then
                if [ "$cuenta" -eq 0 ]; then
                    echo
                    echo -e "  ${YELLOW}${categoria}${NC}"
                fi

                cuenta=$((cuenta + 1))
                printf '    %-24s %b%-10b%b %s\n' \
                    "$(catalog_field "$id" 5)" \
                    "$DIM" "$(catalog_type_label "$(catalog_field "$id" 3)")" "$NC" \
                    "$id"
            fi
        done <<<"$(catalog_apps_in "$categoria")"

        [ "$cuenta" -gt 0 ] && alguna=1
    done <<<"$categorias"

    if [ "$alguna" -eq 0 ]; then
        ui_warning "No hay nada seleccionado."
        return 1
    fi

    echo
    ui_table "Aplicaciones seleccionadas" "$(total_seleccion)"
    return 0
}

# ------------------------------------------------------------
#  Instalación
# ------------------------------------------------------------

ejecutar_instalacion() {
    local lista="$*"
    local id
    local nombre
    local categoria
    local tipo

    # Los índices se mantienen en orden de catálogo, no de pulsación.
    local orden=()
    local candidato

    while IFS= read -r candidato; do
        esta_seleccionado "$candidato" && orden+=("$candidato")
    done <<<"$(catalog_lines | cut -d'|' -f1)"

    ui_step "Preparación"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        ui_warning "MODO SIMULACIÓN: no se instalará nada."
    fi

    checks_repair_apt
    irun "sudo apt update -qq"
    irun "sudo apt install -y curl wget ca-certificates gnupg apt-transport-https"

    if seleccion_necesita_snap "$lista"; then
        ui_info "La selección usa Snap: preparando snapd."
        asegurar_snapd
    fi

    if seleccion_necesita_flatpak "$lista"; then
        ui_info "La selección usa Flatpak: preparando Flathub."
        asegurar_flatpak
    fi

    ui_success "Preparación completada."

    ui_step "Instalación"

    local indice=0
    local total="${#orden[@]}"

    for id in "${orden[@]}"; do
        indice=$((indice + 1))
        nombre="$(catalog_field "$id" 5)"
        categoria="$(catalog_field "$id" 2)"
        tipo="$(catalog_type_label "$(catalog_field "$id" 3)")"

        echo
        ui_info "[$indice/$total] $nombre  ${DIM}($tipo · $categoria · $id)${NC}"

        if [ "$FORZAR" != "1" ] && app_ya_instalada "$id"; then
            ui_skip "Ya está instalado."
            OMITIDOS+=("$id")
            continue
        fi

        if instalar_app "$id"; then
            ui_success "Instalado: $nombre"
            INSTALADOS+=("$id")
        else
            ui_error "Falló la instalación de: $nombre"
            FALLIDOS+=("$id")
        fi
    done

    ui_step "Verificación"

    if [ "$FORZAR" != "1" ]; then
        irun "sudo dpkg --configure -a"
        irun "sudo apt --fix-broken install -y"
    fi

    ui_success "Instalación finalizada."
}

mostrar_informe() {
    local id

    ui_step "Informe"

    if [ "${#INSTALADOS[@]}" -gt 0 ]; then
        echo
        echo -e "  ${GREEN}Instaladas (${#INSTALADOS[@]})${NC}"
        for id in "${INSTALADOS[@]}"; do
            printf '    + %-26s %b\n' "$(catalog_field "$id" 5)" "${DIM}$id${NC}"
        done
    fi

    if [ "${#OMITIDOS[@]}" -gt 0 ]; then
        echo
        echo -e "  ${DIM}Omitidas por ya estar instaladas (${#OMITIDOS[@]})${NC}"
        for id in "${OMITIDOS[@]}"; do
            printf '    = %-26s %b\n' "$(catalog_field "$id" 5)" "${DIM}$id${NC}"
        done
    fi

    if [ "${#FALLIDOS[@]}" -gt 0 ]; then
        echo
        echo -e "  ${RED}Fallidas (${#FALLIDOS[@]})${NC}"
        for id in "${FALLIDOS[@]}"; do
            printf '    ! %-26s %b\n' "$(catalog_field "$id" 5)" "${DIM}$id${NC}"
        done
        echo
        ui_detail "Consulta el registro para ver el detalle de los errores."
    fi

    echo
    echo -e "  ${YELLOW}Notas${NC}"
    echo -e "  ${DIM}·${NC} Cierra sesión y vuelve a entrar si instalaste Docker o Wireshark."
    echo -e "  ${DIM}·${NC} Abre una terminal nueva para que NVM, Rust, Go, Bun y Deno aparezcan en el PATH."
    echo -e "  ${DIM}·${NC} Registro completo: $LOG_FILE"
    echo
}

# ------------------------------------------------------------
#  Argumentos
# ------------------------------------------------------------

analizar_argumentos() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h | --ayuda | --help)
                mostrar_ayuda
                exit 0
                ;;
            --instalar)
                if [ -z "${2:-}" ]; then
                    ui_error "--instalar necesita una lista de ids."
                    exit 1
                fi
                SIN_MENU=1
                seleccionar_por_lista "$2" "--instalar"
                shift 2
                ;;
            --perfil)
                if [ -z "${2:-}" ]; then
                    ui_error "--perfil necesita un nombre."
                    exit 1
                fi
                SIN_MENU=1
                PERFIL_PENDIENTE="$2"
                shift 2
                ;;
            --categoria)
                if [ -z "${2:-}" ]; then
                    ui_error "--categoria necesita un nombre."
                    exit 1
                fi
                SIN_MENU=1
                seleccionar_categorias_nombre "$2"
                shift 2
                ;;
            --todos)
                SIN_MENU=1
                seleccionar_todo
                shift
                ;;
            --sin-menu)
                SIN_MENU=1
                shift
                ;;
            --si | --yes | -y)
                ASSUME_YES=1
                shift
                ;;
            --simular | --dry-run)
                DRY_RUN=1
                shift
                ;;
            --forzar)
                FORZAR=1
                shift
                ;;
            --listar)
                LISTAR_SOLO=1
                shift
                ;;
            --listar-perfiles)
                LISTAR_PERFILES=1
                shift
                ;;
            --desinstalar)
                MODO_DESINSTALAR=1
                shift
                ;;
            --tema)
                MODO_TEMA=1
                shift
                ;;
            --log)
                if [ -z "${2:-}" ]; then
                    ui_error "--log necesita una ruta."
                    exit 1
                fi
                LOG_FILE="$2"
                shift 2
                ;;
            --no-color)
                NO_COLOR=1
                ui_init_colors
                shift
                ;;
            *)
                ui_error "Opción desconocida: $1"
                ui_detail "Ejecuta ./quick_start.sh --ayuda"
                exit 1
                ;;
        esac
    done
}

seleccionar_categorias_nombre() {
    local lista="$1"
    local categoria
    local encontrada=0

    for categoria in ${lista//,/ }; do
        if printf '%s\n' "$(catalog_categories)" | grep -qFx "$categoria"; then
            seleccionar_categoria "$categoria"
            encontrada=1
        else
            ui_error "--categoria: '$categoria' no existe."
            ui_detail "Usa --listar para ver el catálogo."
        fi
    done

    return $((1 - encontrada))
}

# ------------------------------------------------------------
#  Programa principal
# ------------------------------------------------------------

principal() {
    ui_init_colors

    ASSUME_YES="${ASSUME_YES:-0}"
    FORZAR="${FORZAR:-0}"
    PERFIL_PENDIENTE=""
    LISTAR_PERFILES=0

    analizar_argumentos "$@"

    if [ "$LISTAR_SOLO" = "1" ]; then
        listar_catalogo
        return 0
    fi

    if [ "$LISTAR_PERFILES" = "1" ]; then
        listar_perfiles
        return 0
    fi

    ui_banner "QuickStart" "$VERSION"

    ui_step "Comprobaciones del sistema"

    if ! checks_system; then
        ui_pause
        return 1
    fi

    checks_root || {
        ui_pause
        return 1
    }

    if ! checks_sudo; then
        ui_pause
        return 1
    fi

    checks_download_tools

    if [ "$MODO_DESINSTALAR" = "1" ]; then
        ui_step "Modo desinstalación"
        menu_desinstalar
        return 0
    fi

    if [ "$MODO_TEMA" = "1" ]; then
        tema_instalar
        return 0
    fi

    ui_step "Selección de aplicaciones"

    if [ -n "$PERFIL_PENDIENTE" ]; then
        aplicar_perfil_silencioso "$PERFIL_PENDIENTE"
    fi

    if [ "$SIN_MENU" = "0" ] && [ -t 0 ]; then
        menu_principal
    fi

    if ! mostrar_resumen; then
        ui_warning "No hay nada seleccionado."
        ui_detail "Usa el menú, --perfil o --instalar."
        return 0
    fi

    if ! ui_yes_no "¿Continuar con la instalación?"; then
        echo
        ui_info "Cancelado por el usuario."
        return 0
    fi

    # A partir de aquí todo el registro va a un archivo.
    ui_step "Registro"
    ui_detail "La salida completa se guardará en $LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1

    if ! checks_network; then
        ui_error "Instalación cancelada por falta de conexión."
        return 1
    fi

    # Primero la base (git y driver Wi-Fi), después las apps.
    instalar_base

    ejecutar_instalacion "${SELECCION[@]:-}"
    mostrar_informe

    return 0
}

trap 'echo; ui_info "Interrumpido por el usuario."; exit 130' INT

# QUICKSTART_NO_EJECUTAR permite que los tests carguen este archivo
# sin lanzar la instalación.
if [ "${QUICKSTART_NO_EJECUTAR:-0}" != "1" ]; then
    principal "$@"
fi
