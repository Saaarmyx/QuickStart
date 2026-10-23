# Seguridad de QuickStart

QuickStart instala software con `sudo`, descarga paquetes y ejecuta instaladores de terceros. Cualquier fallo que permita ejecutar comandos no deseados, saltarse una comprobación o modificar archivos fuera del alcance previsto se considera un problema de seguridad.

## Versiones soportadas

La versión pública documentada es `1.0.0` (2026-10-13). El repositorio aún no tiene tags, así que se mantiene la última revisión de la rama `main`.

| Versión | Soporte |
| --- | --- |
| `1.0.0` (última revisión de `main`) | Sí |
| Versiones anteriores | No |

## Cómo reportar una vulnerabilidad

Usa el **reporte privado de GitHub**:

1. Entra en la pestaña **Security** del repositorio.
2. Pulsa **Report a vulnerability**.
3. Rellena el formulario con el detalle indicado abajo.

Si el reporte privado no está habilitado, contacta conmigo desde mi perfil de GitHub: [github.com/Saaarmyx](https://github.com/Saaarmyx).

**No abras un issue público** para reportar una vulnerabilidad y no publiques un script que la explote antes de que exista una corrección.

## Qué incluir en el reporte

- Descripción del problema.
- Pasos para reproducirlo, con la versión de Ubuntu y la arquitectura.
- Impacto: qué comando se ejecuta, con qué privilegios y qué archivos se modifican.
- Versión o commit afectado.
- Una propuesta de corrección, si la tienes.

## Tiempos

Es un proyecto personal. Respondo en cuanto puedo, sin plazos garantizados. Confirmaré la recepción y te contaré cómo avanza la revisión.

## Divulgación responsable

Te pido que no divulges el detalle hasta que exista una corrección publicada. Si el fallo permite ejecutar código como root, la prioridad será publicar una salvaguarda cuanto antes.

## Reconocimiento

Si quieres, te acredito en el CHANGELOG o en la publicación de la corrección. Indica al reportar cómo prefieres aparecer.
