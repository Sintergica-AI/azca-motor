# Avisos

Azca es una obra derivada de **Hermes Agent**, de Nous Research, distribuida
bajo licencia MIT. El texto de la licencia y el aviso de copyright originales
están en [`LICENSE`](LICENSE) y acompañan a toda copia de este código, como
exige la MIT.

Los cambios respecto al original son obra de Sintérgica AI y se publican bajo
la misma licencia MIT:

    Portions Copyright (c) 2026 Sintérgica AI

## Qué cambia respecto a Hermes Agent

- `scripts/install.sh` y `scripts/install.ps1`: el origen del motor es
  configurable por entorno (`HERMES_REPO_URL`, `HERMES_REPO_URL_SSH`,
  `HERMES_BRANCH`), para instalar desde una rama, un fork o un espejo propio
  sin editar el script.
- `scripts/publicar-espejo.sh` y `deploy/espejo/`: publicación opcional del
  motor como espejo estático para redes sin acceso a GitHub.

## Marcas

Hermes Agent y Nous Research son marcas de sus titulares. Azca y Lattice Kaná
son marcas de Sintérgica AI. Este proyecto no está afiliado, patrocinado ni
respaldado por Nous Research.
