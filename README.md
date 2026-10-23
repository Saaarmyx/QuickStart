<div align="center">

# QuickStart

Instalador interactivo de aplicaciones para Ubuntu: eliges del menú y el script se encarga del resto.

[![Licencia](https://img.shields.io/badge/Licencia-Apache_2.0-D22128?logo=apache&logoColor=white)](LICENSE)
![Estado](https://img.shields.io/badge/Estado-Estable-22C55E)
![Versión](https://img.shields.io/badge/Versión-1.0.0-8B5CF6)
![Bash](https://img.shields.io/badge/Bash-5.0%2B-4EAA25?logo=gnu-bash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20%7C%2026.04-E95420?logo=ubuntu&logoColor=white)

</div>

## Estado del proyecto

**Estable.** La versión `1.0.0` está documentada en el CHANGELOG y el script cubre instalación, personalización y desinstalación. Sigo añadiendo aplicaciones y perfiles cuando los necesito.

## Descripción

QuickStart reúne en un solo script de Bash lo que antes eran tres: la instalación limpia de aplicaciones, el driver Wi-Fi MediaTek MT7902 y las utilidades de escritorio. La idea es preparar una máquina Ubuntu nueva sin ir copiando comandos de un bloc de notas.

El catálogo tiene más de 110 aplicaciones en 12 categorías y 10 perfiles listos. No desinstala nada por sorpresa, detecta lo que ya está instalado, omite los `.deb` que no existen para `arm64` y deja un registro de todo lo que hizo.

## Características principales

- Menú interactivo con selección acumulada entre categorías.
- 10 perfiles rápidos: `minimal`, `frontend`, `backend`, `data`, `devops`, `mobile`, `multimedia`, `gamedev`, `social` y `privacidad`.
- Seis motores de instalación: `apt`, `snap`, `flatpak`, `deb`, `ppa` y manejadores `custom`.
- Base del sistema obligatoria: `git` primero y driver Wi-Fi solo si el chip está presente.
- Tema GTK MacTahoe-Dark incluido, con iconos y cursores WhiteSur opcionales.
- Modo de desinstalación con protección de paquetes base.
- Modo simulación (`--simular`), registro configurable y salida sin colores.
- CLI completa para automatizar instalaciones sin pasar por el menú.
- Validador de catálogo y prueba de la lógica de menús.

## Requisitos

| Requisito | Detalle |
| --- | --- |
| Sistema | Ubuntu 24.04 LTS o 26.04 LTS. En otras distribuciones se avisa y se detiene. |
| Arquitectura | `amd64` completa. En `arm64` funciona, pero se omiten los `.deb` no disponibles. |
| Privilegios | Usuario normal con `sudo`. **No** ejecutes el script como root. |
| Red | Necesaria para descargar índices e instaladores. |
| Dependencias | Solo `bash`, `dpkg` y `sudo`. El script instala `curl` y `wget` si faltan. |

## Instalación

```bash
git clone https://github.com/Saaarmyx/QuickStart.git
cd QuickStart
chmod +x quick_start.sh
./quick_start.sh
```

No hay nada que compilar: es Bash puro.

## Uso

### Menú interactivo

```bash
./quick_start.sh
```

Dentro de cada categoría marcas y desmarcas con los números. La selección se acumula, confirmas una vez al final y la instalación empieza.

### Perfiles

```bash
./quick_start.sh --perfil devops
./quick_start.sh --perfil backend --si
./quick_start.sh --perfil devops --simular
```

### Instalación puntual

```bash
./quick_start.sh --instalar node,rust,python,vscode
./quick_start.sh --categoria "Terminal y utilidades" --perfil gamedev --si
ASSUME_YES=1 ./quick_start.sh --perfil devops --log /var/log/quickstart.log
```

### Otras opciones

```bash
./quick_start.sh --listar             # catálogo completo
./quick_start.sh --listar-perfiles    # perfiles disponibles
./quick_start.sh --desinstalar        # quitar apps del catálogo
./quick_start.sh --tema               # instalar el tema incluido
./quick_start.sh --ayuda
```

| Opción | Qué hace |
| --- | --- |
| `--instalar LISTA` | Instala los ids indicados, separados por comas. |
| `--perfil NOMBRE` | Aplica un perfil. |
| `--categoria NOMBRE` | Selecciona una categoría completa. Admite comas. |
| `--todos` | Selecciona el catálogo entero. |
| `--sin-menu` | Instala directamente lo indicado. |
| `--si`, `--yes`, `-y` | No pide confirmación final. |
| `--simular`, `--dry-run` | Muestra qué haría sin tocar nada. |
| `--forzar` | Reinstala aunque la app ya esté presente. |
| `--listar`, `--listar-perfiles` | Lista y termina. |
| `--desinstalar` | Entra al modo de desinstalación. |
| `--tema` | Instala y aplica el tema incluido (GNOME). |
| `--log RUTA` | Guarda el registro en la ruta indicada. |
| `--no-color` | Desactiva los colores. |
| `--ayuda`, `-h` | Ayuda. |

Variables de entorno: `ASSUME_YES=1`, `NO_COLOR=1` y `LOG_FILE`.

## Estructura del proyecto

```text
QuickStart/
├── quick_start.sh          # Punto de entrada: menú, CLI y orquestación
├── lib/
│   ├── ui.sh               # Colores, banners, mensajes y preguntas
│   ├── checks.sh           # Comprobaciones del sistema
│   ├── catalog.sh          # Catálogo de aplicaciones y perfiles
│   ├── installers.sh       # Motores de instalación y manejadores custom
│   ├── wifi.sh             # Detección e instalación del driver Wi-Fi
│   ├── themes.sh           # Tema e iconos
│   └── removers.sh         # Desinstalación
├── themes/
│   └── MacTahoe-Dark/      # Tema GTK incluido
├── tests/
│   ├── validar_catalogo.sh # Integridad del catálogo
│   └── probar_menu.sh      # Lógica de menús y selección
├── docs/
│   └── CONTRIBUTING.md     # Guía detallada para añadir apps
├── CHANGELOG.md
├── SECURITY.md
└── README.md
```

## Hoja de ruta

- [x] Menú interactivo con 12 categorías y selección acumulada.
- [x] 10 perfiles rápidos y catálogo de más de 110 aplicaciones.
- [x] Driver Wi-Fi MT7902 con detección de compatibilidad.
- [x] Tema MacTahoe-Dark e iconos WhiteSur opcionales.
- [x] Desinstalación con protección de paquetes base.
- [x] Validador de catálogo y prueba de menús.
- [ ] Crear el tag `v1.0.0` que ya se menciona en el CHANGELOG.
- [ ] Añadir integración continua con ShellCheck y `bash -n`.
- [ ] Ampliar la suite de tests para instaladores `custom`.
- [ ] Documentar el esquema de una entrada del catálogo con todos sus campos.

## Contribuir

Se aceptan apps nuevas, correcciones y mejoras de documentación. Empieza por [CONTRIBUTING.md](CONTRIBUTING.md); la guía detallada para añadir una aplicación está en [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Seguridad

QuickStart ejecuta `sudo` y descarga instaladores de terceros. Si encuentras una forma de ejecutar comandos no deseados o de saltarte las comprobaciones, sigue [SECURITY.md](SECURITY.md) y no lo publiques en un issue.

## Licencia

Este proyecto se distribuye bajo **Apache License 2.0** (`Apache-2.0`). Consulta [LICENSE](LICENSE) y [NOTICE](NOTICE).

Apache 2.0 permite usar, modificar y redistribuir el software, con o sin fines comerciales, siempre que se conserve el aviso de copyright, se incluya una copia de la licencia y se indiquen los cambios. También incluye una concesión de patentes y requiere conservar los avisos de atribución.

Es un proyecto personal de Santiago Sarmiento. No está afiliado a Nexora ni utiliza su marca. Las marcas y nombres de las aplicaciones que instala pertenecen a sus respectivos dueños; cada app se descarga desde su fuente oficial.

---

Hecho por Santiago Sarmiento
