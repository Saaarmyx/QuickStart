# Cómo contribuir en QuickStart

Gracias por querer participar. El proyecto es a propósito sencillo: bash, sin
dependencias ni compilación. Cualquiera puede añadir una aplicación sin tocar
la lógica del programa.

## Antes de empezar

```bash
git clone https://github.com/Saaarmyx/QuickStart.git
cd QuickStart
```

No hay nada que compilar ni dependencias que instalar.

## Antes de enviar cambios

```bash
./tests/validar_catalogo.sh
bash -n quick_start.sh
```

Si tienes `shellcheck`:

```bash
shellcheck quick_start.sh lib/*.sh tests/*.sh
```

`validar_catalogo.sh` debe salir con código 0.

---

## Añadir una aplicación

### 1. Añade una línea al catálogo

En `lib/catalog.sh`, dentro del bloque `CATALOG_RAW`, en la categoría que
corresponda.

```
id|categoría|tipo|argumento|nombre|descripción|comprobación
```

| Campo          | Reglas                                                                                                                                   |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `id`           | Minúsculas, números y guiones. Empieza por letra o número. Es el nombre que se usa en `--instalar`, así que debe ser corto y predecible. |
| `categoría`    | Debe coincidir **exactamente** con una categoría ya existente, o se creará un grupo nuevo en el menú.                                    |
| `tipo`         | `apt`, `snap`, `flatpak`, `deb`, `ppa` o `custom`.                                                                                       |
| `argumento`    | Paquetes separados por espacio, nombre de snap, id de Flatpak, URL del `.deb` o nombre del manejador `custom`.                           |
| `nombre`       | Lo que ve el usuario en el menú.                                                                                                         |
| `descripción`  | Una línea corta que explique para qué sirve.                                                                                             |
| `comprobación` | Opcional. Si la dejas vacía se deduce del tipo.                                                                                          |

No uses el carácter `|` dentro de un campo: es el separador.

### 2. Ejemplos

Paquete de apt:

```
htop|Red y seguridad|apt|htop|htop|Monitor de procesos|
```

Varios paquetes a la vez:

```
ripgrep|Terminal y utilidades|apt|ripgrep fd-find|ripgrep + fd|Búsqueda rápida de texto y archivos|
```

Snap:

```
telegram|Social y comunicación|snap|telegram-desktop|Telegram Desktop|Mensajería rápida y cifrada|
```

Flatpak:

```
signal|Social y comunicación|flatpak|org.signal.Signal|Signal|Mensajería privada de código abierto|
```

`.deb` oficial:

```
discord|Social y comunicación|deb|https://discord.com/api/download?platform=linux&format=deb|Discord|Voice, chat y comunidad|
```

PPA:

```
terraform|Contenedores y DevOps|ppa|ppa:hashicorp/terraform|Terraform|Infrastructura como código|
```

### 3. Comprobación explícita

Si la detección automática no sirve para tu aplicación, declara la
comprobación en el último campo:

| Formato                 | Qué hace                                   |
| ----------------------- | ------------------------------------------ |
| `apt:pkg1,pkg2`         | Todos los paquetes deben estar instalados. |
| `snap:nombre`           | `snap list nombre`                         |
| `flatpak:id`            | `flatpak info id`                          |
| `bin:comando1,comando2` | Basta con que exista uno de los comandos.  |
| `path:/ruta`            | La ruta debe existir.                      |

```
claude|IA y asistentes|deb|https://...|Claude Code|Asistente de Anthropic|bin:claude
```

Si no declaras nada y el tipo es `deb`, el script reinstala siempre, porque no
hay forma fiable de saber si un `.deb` externo ya está presente.

---

## Añadir un manejador `custom`

Úsalo cuando el tipo `deb` no basta porque hacen falta varios pasos: añadir un
repositorio, descargar un instalador oficial o responder sí a una pregunta de
`debconf`.

En `lib/installers.sh` añade **dos** funciones. El nombre sale del campo
`argumento` de la entrada del catálogo:

```bash
# ¿Ya está instalado?
custom_miapp_instalada() {
    command -v miapp >/dev/null 2>&1
}

# Cómo se instala
custom_miapp() {
    irun "sudo apt install -y miapp"
}
```

Reglas:

- Usa siempre `irun` para ejecutar órdenes. Así `--simular` funciona solo.
- Si necesitas descargar, usa `curl -fL --progress-bar` y borra el temporal
  al terminar, también en el camino de error.
- Si tocas el `PATH`, llama a `agregar_al_perfil`. Es idempotente.
- Si el paquete hace preguntas interactivas, usa
  `sudo env DEBIAN_FRONTEND=noninteractive apt install -y`.
- Si añades el usuario a un grupo, avisa de que hay que cerrar sesión.
- Si necesitas otro gestor de paquetes, llámalo desde `asegurar_snapd` o
  `asegurar_flatpak` antes de usarlo.

Un ejemplo real, el de Go, que consulta la última versión antes de descargar:

```bash
custom_go_instalada() {
    [ -x "$ruta_go/bin/go" ] || command -v go >/dev/null 2>&1
}

custom_go() {
    local version
    version="$(curl -fsSL https://go.dev/VERSION?m=text | head -n 1)"
    # ... descarga e instalación ...
}
```

---

## Crear o cambiar un perfil

En `lib/catalog.sh`, dentro de `PROFILES_RAW`. Tres campos:

```
nombre|descripción|id1 id2 id3
```

Los ids deben existir en el catálogo; el validador lo comprueba. Mantén el
nombre corto: es lo que se escribe en `--perfil`.

---

## Añadir una categoría

No requiere tocar código. Añade el grupo de aplicaciones con un nombre de
categoría nuevo en el catálogo y aparecerá en el menú en el orden en el que
aparezca la primera entrada. Si insertas una categoría entre dos existentes,
usa un separador de comentarios para que quede legible.

---

## Estilo del código

- Bash con `set -uo pipefail`. Sin `set -e`: una instalación que falla no debe
  abortar el resto.
- Cuatro espacios de sangría, sin tabuladores.
- Comillas en todas las expansiones de variables.
- Comentarios y texto de cara al usuario **en español**.
- Los mensajes van por `ui_*`, nunca por `echo` suelto.
- `local` para todas las variables de función.

---

## Commits

Mensajes en español, en imperativo y en una línea:

```
Añade Bun y Deno al catálogo
Corrige la detección de perfiles
Documenta el modo simulación
```

Un commit hace una cosa. Si mezclas catálogo y documentación, sepáralos.

---

## Pull requests

1. Ejecuta `./tests/validar_catalogo.sh` y asegúrate de que sale con 0.
2. Ejecuta `bash -n quick_start.sh`.
3. Prueba en simulación lo que hayas cambiado:
   `./quick_start.sh --instalar TU_ID --simular`
4. Añade la entrada a la sección **No publicado** de `CHANGELOG.md`.
5. Explica en la descripción qué añade y cómo lo has probado.

Si añades una aplicación, indica de dónde viene la URL y qué comando la
verifica como ya instalada.

---

## Reportar errores

Incluye:

- Versión de Ubuntu (`lsb_release -ds`).
- Arquitectura (`dpkg --print-architecture`).
- El comando que ejecutaste.
- La salida de `./quick_start.sh --instalar TU_ID --simular`.
- El fragmento relevante del registro.

---

## Licencia

Al contribuir aceptas que tu trabajo se publique bajo la licencia MIT del
proyecto, la misma que cubre el resto del repositorio.
