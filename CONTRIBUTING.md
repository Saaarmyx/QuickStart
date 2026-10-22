# Guía de Contribución — QuickStart

> Instalador interactivo de +110 apps para Ubuntu (bash puro).  
> La guía completa y detallada está en **[docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md)**.

---

## 🚀 Resumen Rápido

### Flujo Básico

```bash
# 1. Fork + Clona tu fork
git clone https://github.com/TU-USUARIO/Saaarmyx.git
cd Saaarmyx/QuickStart

# 2. Rama desde main
git checkout main
git pull upstream main
git checkout -b feature/mi-mejora   # fix/, docs/, refactor/, style/, build/, ci/, test/

# 3. Cambios + Commits Conventional Commits
git add lib/catalog.sh lib/installers.sh
git commit -m "feat(catalog): añade Bun y Deno al catálogo"

# 4. Push + PR
git push origin feature/mi-mejora
# Abre PR hacia Saaarmyx/Saaarmyx:main (carpeta QuickStart/)
```

### Convención de Ramas y Commits

| Prefijo Rama | Tipo Commit | Uso |
|--------------|-------------|-----|
| `feature/` | `feat` | Nueva app, perfil, categoría, opción CLI |
| `fix/` | `fix` | Corrección bug (detección, instalación, menú) |
| `refactor/` | `refactor` | Reorganización sin cambio comportamiento |
| `docs/` | `docs` | README, CHANGELOG, docs/CONTRIBUTING.md |
| `style/` | `style` | Formato (shellcheck), sin lógica |
| `build/` | `build` | Scripts de build, CI, packaging |
| `ci/` | `ci` | GitHub Actions, automatización |
| `test/` | `test` | Tests (validar_catalogo.sh, probar_menu.sh) |

**Ámbitos QuickStart**: `catalog`, `installers`, `ui`, `checks`, `wifi`, `themes`, `removers`, `profiles`.

### Checks Obligatorios Antes de PR

```bash
# 1. Validador de catálogo (debe salir con código 0)
./tests/validar_catalogo.sh

# 2. Sintaxis bash
bash -n quick_start.sh lib/*.sh tests/*.sh

# 3. Shellcheck (si lo tienes instalado)
shellcheck quick_start.sh lib/*.sh tests/*.sh

# 4. Simula tu cambio
./quick_start.sh --instalar TU_ID --simular
```

### Checklist PR

- [ ] `main` actualizado y rebaseado
- [ ] Commits atómicos + Conventional Commits (español, imperativo, minúsculas)
- [ ] Checks arriba pasan
- [ ] `CHANGELOG.md` actualizado (sección "No publicado")
- [ ] `docs/CONTRIBUTING.md` actualizado si cambias formato de catálogo/perfiles
- [ ] PR explica **qué, por qué, cómo probaste** (incluye salida de simulación)

---

## 📋 Formato de Catálogo (Resumen)

Una línea en `lib/catalog.sh` bloque `CATALOG_RAW`:

```
id|categoría|tipo|argumento|nombre|descripción|comprobación
```

| Campo | Reglas |
|-------|--------|
| `id` | Minúsculas, números, guiones; empieza por letra/número; corto y predecible |
| `categoría` | Coincide exactamente con existente o crea grupo nuevo |
| `tipo` | `apt`, `snap`, `flatpak`, `deb`, `ppa`, `custom` |
| `argumento` | Paquetes (espacio), snap name, flatpak id, URL .deb, nombre handler custom |
| `nombre` | Lo que ve el usuario en menú |
| `descripción` | Una línea, para qué sirve |
| `comprobación` | Opcional: `apt:pkg1,pkg2`, `snap:nombre`, `flatpak:id`, `bin:cmd1,cmd2`, `path:/ruta` |

**Ejemplo**:
```
neovim|Editores e IDEs|custom|neovim|Neovim|Editor modal moderno|
```

Si `tipo=custom`, añade **dos** funciones en `lib/installers.sh`:
```bash
custom_neovim_instalada() { command -v nvim >/dev/null 2>&1; }
custom_neovim() { irun "curl -fL ... | tar -xz ..."; }
```

---

## 🎨 Estándares Bash (QuickStart)

| Regla | Detalle |
|-------|---------|
| Shebang | `#!/usr/bin/env bash` |
| Modo estricto | `set -uo pipefail` (**sin** `set -e`) |
| Indentación | 4 espacios, **sin tabs** |
| Comillas | Siempre en expansiones: `"$var"`, `"${arr[@]}"` |
| Variables | `local` en funciones; `readonly` para constantes |
| Ejecución | Usa `irun` (wrapper que respeta `--simular`) |
| Mensajes | Funciones `ui_*` (nunca `echo` suelto) |
| Comentarios | En español, explican **por qué**, no **qué** |
| Validación | `bash -n` + `shellcheck` antes de commit |

---

## 🐛 Reportar Issues

Incluye:
- Ubuntu version (`lsb_release -ds`)
- Arquitectura (`dpkg --print-architecture`)
- Comando ejecutado
- Salida de `./quick_start.sh --instalar TU_ID --simular`
- Fragmento relevante del log (`/tmp/quickstart-*.log`)

---

## 📜 Licencia de Contribuciones

Al enviar PR, aceptas que tu código se licencie bajo **MIT** (misma licencia del proyecto). Ver [LICENSE](./LICENSE).

---

## 🤔 Dudas

- GitHub Discussions / Issues.
- Discord `saaarmyx` o @saaarmyx en GitHub.