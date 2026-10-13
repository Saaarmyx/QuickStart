<h1 align="center">Bienvenido a QuickStart</h1>

Instalador interactivo de aplicaciones para Ubuntu: eliges del menú y el script se encarga del resto.

Para aprender más sobre el uso del proyecto, visita la [documentación oficial]().

## Tabla de Contenidos

- [Estado del proyecto](#estado-del-proyecto)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Primeros Pasos](#primeros-pasos)
  - [Guía de Inicio Rápido](#guía-de-inicio-rápido)
  - [Guía de Desarrollo](#guía-de-desarrollo)

## Estado del proyecto

> **Estado actual:** Activo

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

## Estructura del proyecto

```text
QuickStart/
├── quick_start.sh          # Punto de entrada: menú, CLI y orquestación
├── lib/                    # Scripts de soporte
├── themes/                 # Tema GTK incluido
├── tests/                  # Validador y pruebas
├── CHANGELOG.md          # Historial de cambios
├── LICENSE               # Licencia
├── NOTICE                # Avisos de atribución
└── README.md             # Documentación principal
```

## Primeros Pasos

Clona este repositorio y configura el entorno inicial ejecutando los siguientes comandos:

```bash
# 1. Clona el repositorio
git clone https://github.com/Saaarmyx/QuickStart.git

# 2. Entra al directorio
cd QuickStart
```

### Guía de Inicio Rápido

1. **Instalar dependencias**

   No se requieren dependencias externas. Solo necesitas `bash`, `dpkg` y `sudo`.

2. **Ejecutar el proyecto**

   ```bash
   chmod +x quick_start.sh
   ./quick_start.sh
   ```

### Guía de Desarrollo

Para contribuir al código del proyecto:

1. Crea una rama para tu cambio:

   ```bash
   git checkout -b nombre-de-la-rama
   ```

2. Realiza tus cambios y commitea:

   ```bash
   git commit -m "Descripción breve del cambio"
   ```

3. Sube los cambios:

   ```bash
   git push origin nombre-de-la-rama
   ```

---

<p align="center">
  Desarrollado por <strong>Saaarmyx</strong>.
</p>
