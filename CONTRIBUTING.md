# Contribuir a QuickStart

Gracias por querer mejorar QuickStart. Es un proyecto personal, pero está pensado para que añadir una aplicación sea sencillo y para que cualquier persona pueda revisar lo que el script va a ejecutar.

## Antes de empezar

Si tu cambio es grande (un motor de instalación nuevo, una reestructuración de `lib/` o un modo de desinstalación distinto), abre primero un issue. Para añadir una app al catálogo o corregir una entrada, puedes enviar el Pull Request directamente.

## Flujo de trabajo

1. Haz un fork del repositorio.
2. Crea una rama desde `main`:

   ```bash
   git checkout -b feat/nueva-app
   ```

   Usa prefijos `feat/`, `fix/` o `docs/` y nombres en kebab-case.

3. Haz commits atómicos con [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/):

   ```text
   feat(catalogo): añade Zed al catálogo de editores
   fix(installers): corrige la ruta de OpenCode en npm
   docs(readme): documenta el perfil de datos
   ```

4. Abre un Pull Request contra `main` y describe qué probaste.

## Entorno de desarrollo

Solo necesitas Ubuntu 24.04/26.04, `bash` y `sudo` para probar la instalación. Para el desarrollo no hace falta compilar nada.

```bash
git clone https://github.com/Saaarmyx/QuickStart.git
cd QuickStart
chmod +x quick_start.sh

# Ver el catálogo y los perfiles
./quick_start.sh --listar
./quick_start.sh --listar-perfiles

# Simular una instalación
./quick_start.sh --perfil backend --simular

# Validar el catálogo y la lógica de menús
./tests/validar_catalogo.sh
./tests/probar_menu.sh
```

Comprobaciones de sintaxis y análisis estático:

```bash
bash -n quick_start.sh
bash -n lib/*.sh
bash -n tests/*.sh
shellcheck quick_start.sh lib/*.sh tests/*.sh
```

`shellcheck` es opcional, pero si lo tienes instalado, pásalo antes de enviar el PR.

## Estándares de código

- **Bash:** 4 espacios, `snake_case` para funciones y variables, mensajes en español.
- **Catálogo:** una línea por app en `lib/catalog.sh`, con el formato documentado en `docs/CONTRIBUTING.md`.
- **Instaladores:** los pasos propios van en `lib/installers.sh` como `custom_<app>` y su comprobación como `custom_<app>_instalada`.
- **Desinstaladores:** si la app necesita limpieza propia, añade `custom_<app>_desinstalar` en `lib/removers.sh`.
- **Formato:** respeta `.editorconfig` (UTF-8, LF, 4 espacios).
- **Tests:** `tests/validar_catalogo.sh` debe pasar siempre. Si tocas menús, ejecuta también `tests/probar_menu.sh`.

## Checklist del Pull Request

- [ ] El cambio está explicado y tiene un caso de uso claro.
- [ ] `./tests/validar_catalogo.sh` pasa.
- [ ] `./tests/probar_menu.sh` pasa si toqué menús.
- [ ] `bash -n quick_start.sh` y `bash -n lib/*.sh` pasan.
- [ ] `shellcheck` no reporta errores nuevos (si está instalado).
- [ ] Probé el flujo con `--simular` en Ubuntu 24.04 o 26.04.
- [ ] Actualicé `README.md` y `CHANGELOG.md` si cambia el comportamiento visible.
- [ ] No incluí credenciales, rutas personales ni logs.
- [ ] El commit sigue Conventional Commits.

## Proceso de revisión

Reviso los PR cuando puedo, sin plazos fijos. Los cambios que tocan instaladores o `sudo` pueden tardar más porque necesito probarlos en una máquina virtual. Te responderé en el propio PR con dudas o cambios solicitados.

## Acuerdo de contribución

No hay CLA. Al enviar una contribución aceptas que se incorpore al proyecto bajo **Apache License 2.0** (`Apache-2.0`), la misma licencia del repositorio.

## Código de conducta

- Respeta a las demás personas, aunque no compartas su criterio.
- Crítica el código, no a quien lo escribió.
- No publiques datos personales, credenciales ni información de terceros.
- No propongas instalar software desde fuentes no oficiales.
- Si detectas un problema de seguridad, repórtalo en privado antes de hacerlo público.

## Licencia

Las contribuciones quedan bajo **Apache License 2.0** (`Apache-2.0`). Consulta [LICENSE](LICENSE) y [NOTICE](NOTICE).
