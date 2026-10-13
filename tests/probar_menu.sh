#!/usr/bin/env bash

# ============================================================
#  QuickStart · tests/probar_menu.sh
# ============================================================
#  Prueba la lógica de los menús y de la selección sin instalar
#  nada y sin tocar el sistema.
#
#    ./tests/probar_menu.sh
#
#  Sale con código 0 si todas las comprobaciones pasan.
# ============================================================

set -uo pipefail

RAIZ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Carga el programa principal sin ejecutarlo.
export INICIO_RAPIDO_NO_EJECUTAR=1
# shellcheck source=/dev/null
. "$RAIZ/quick_start.sh"

HOST_ARCH="amd64"
VERSION="test"
ERRORES=0

fallo() {
    ui_error "$1"
    ERRORES=$((ERRORES + 1))
}

comprobar() {
    local descripcion="$1"
    local esperado="$2"
    local obtenido="$3"

    if [ "$esperado" = "$obtenido" ]; then
        ui_success "$descripcion"
    else
        fallo "$descripcion (esperado: '$esperado', obtenido: '$obtenido')"
    fi
}

ui_init_colors
SELECCION=()

# ------------------------------------------------------------
#  Selección y deselección
# ------------------------------------------------------------

ui_step "1. Selección y deselección"

agregar_seleccion node
agregar_seleccion rust
agregar_seleccion node
comprobar "No duplica al añadir dos veces" "2" "${#SELECCION[@]}"

agregar_seleccion python
comprobar "Acumula en orden" "node rust python" "${SELECCION[*]}"

alternar_seleccion rust
comprobar "Alternar quita lo seleccionado" "node python" "${SELECCION[*]}"

alternar_seleccion rust
comprobar "Alternar vuelve a añadirlo" "node python rust" "${SELECCION[*]}"

quitar_seleccion node
quitar_seleccion python
quitar_seleccion rust
comprobar "Vaciar deja el array a cero" "0" "${#SELECCION[@]}"

# El array vacío no debe romper el recorrido.
if esta_seleccionado node; then
    fallo "esta_seleccionado()] dice que sí con la lista vacía"
else
    ui_success "esta_seleccionado()] con la lista vacía"
fi

# ------------------------------------------------------------
#  Categorías completas
# ------------------------------------------------------------

ui_step "2. Selección por categoría"

SELECCION=()
seleccionar_categoria "Lenguajes y runtimes"
total_en_runtimes="$(catalog_apps_in "Lenguajes y runtimes" | wc -l | tr -d ' ')"
comprobar "Selecciona la categoría entera" "$total_en_runtimes" "$(contar_en_categoria "Lenguajes y runtimes")"
comprobar "No toca otras categorías" "0" "$(contar_en_categoria "Gaming")"

# ------------------------------------------------------------
#  Menú de categoría con entrada simulada
# ------------------------------------------------------------

ui_step "3. Menú de categoría"

# Ojo: una tubería a la derecha ejecutaría el menú en una subshell
# y perderíamos la selección. Con here-strings no hay subshell.
SELECCION=()
menu_categoria "Gaming" <<<'1 3
ninguno
1
todos
v' >/dev/null 2>&1

comprobar "«todos» marca la categoría completa" \
    "$(catalog_apps_in "Gaming" | wc -l | tr -d ' ')" \
    "$(contar_en_categoria "Gaming")"

SELECCION=()
menu_categoria "Gaming" <<<'todos
ninguno' >/dev/null 2>&1
comprobar "«ninguno» vacía la categoría" "0" "$(contar_en_categoria "Gaming")"

SELECCION=()
menu_categoria "Gaming" <<<'1 1
v' >/dev/null 2>&1
comprobar "Repetir un número lo marca y lo desmarca" "0" "${#SELECCION[@]}"

SELECCION=()
menu_categoria "Gaming" <<<'999
abc
v' >/dev/null 2>&1
comprobar "Una opción inválida no selecciona nada" "0" "${#SELECCION[@]}"

SELECCION=()
menu_categoria "Gaming" <<<'1,3
v' >/dev/null 2>&1
comprobar "Acepta números separados por coma" "2" "${#SELECCION[@]}"

SELECCION=()
menu_categoria "Gaming" <<<'2
v' >/dev/null 2>&1
comprobar "Marca un número suelto" "1" "${#SELECCION[@]}"
# La segunda entrada de la categoría Gaming es Lutris.
comprobar "Y es la app de esa posición" "lutris" "${SELECCION[*]}"

SELECCION=()
menu_categoria "Gaming" <<<'1 3
v' >/dev/null 2>&1
comprobar "Acepta varios números separados por espacio" "steam heroic" "${SELECCION[*]}"

# ------------------------------------------------------------
#  Perfiles
# ------------------------------------------------------------

ui_step "4. Perfiles"

SELECCION=()
cargar_perfil devops >/dev/null 2>&1
esperados_devops="$(profile_apps devops | wc -w | tr -d ' ')"
comprobar "El perfil devops carga sus ids" "$esperados_devops" "${#SELECCION[@]}"

SELECCION=()
if cargar_perfil no-existe >/dev/null 2>&1; then
    fallo "Un perfil inexistente debería devolver error"
else
    ui_success "Un perfil inexistente devuelve error"
fi

comprobar "Un perfil inexistente no selecciona nada" "0" "${#SELECCION[@]}"

# ------------------------------------------------------------
#  Selección por lista de CLI
# ------------------------------------------------------------

ui_step "5. Selección por línea de comandos"

SELECCION=()
seleccionar_por_lista "node,rust,python" "test" >/dev/null 2>&1
comprobar "Lista separada por comas" "3" "${#SELECCION[@]}"

SELECCION=()
seleccionar_por_lista "node rust python" "test" >/dev/null 2>&1
comprobar "Lista separada por espacios" "3" "${#SELECCION[@]}"

SELECCION=()
seleccionar_por_lista "node,no-existe" "test" >/dev/null 2>&1
comprobar "Un id inválido no cuela en la selección" "1" "${#SELECCION[@]}"

# ------------------------------------------------------------
#  Detección de dependencias de la selección
# ------------------------------------------------------------

ui_step "6. Detección de snap y flatpak"

if seleccion_necesita_snap "telegram spotify"; then
    ui_success "Detecta que Telegram necesita snap"
else
    fallo "No detectó que telegram necesita snap"
fi

if seleccion_necesita_snap "node rust python"; then
    fallo "Detectó snap donde no hace falta"
else
    ui_success "Una lista de apt no pide snap"
fi

if seleccion_necesita_flatpak "signal slack"; then
    ui_success "Detecta que Signal necesita flatpak"
else
    fallo "No detectó que signal necesita flatpak"
fi

# ------------------------------------------------------------
#  Resumen
# ------------------------------------------------------------

echo
ui_step "Resumen"

if [ "$ERRORES" -eq 0 ]; then
    ui_success "Todos los tests del menú pasan."
    exit 0
fi

ui_error "Fallaron $ERRORES comprobaciones."
exit 1
