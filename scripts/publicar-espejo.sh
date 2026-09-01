#!/usr/bin/env bash
#
# Publica el motor en el espejo propio (Azca).
#
# POR QUÉ EXISTE
#
# El fork del motor es privado, y el escritorio instala el motor con un `git
# clone` ANÓNIMO. Un repositorio privado devuelve 404, así que lo que se sirve
# a los usuarios es este espejo de sólo lectura en dominio propio.
#
# Se publica como REPOSITORIO GIT y no como tarball porque `hermes update` y la
# rama de actualización del propio instalador trabajan sobre un checkout: un
# tarball dejaría a los usuarios sin actualizaciones del motor.
#
# Y se publica APLASTADO —un commit por versión— por una razón medida: un
# repositorio servido como ficheros estáticos usa el transporte "tonto" de git,
# que ABORTA ante `--depth` con «dumb http transport does not support shallow
# capabilities». Sin poder clonar en superficial, un espejo con el historial
# entero obligaría a cada usuario a bajarse 666 MB. Aplastado, el clon completo
# pesa lo que pesa el código (~76 MB comprimidos) y no hace falta montar un
# servidor git inteligente: basta el `file_server` de Caddy que ya corre.
#
# Cada publicación es un commit ENCIMA de la anterior, nunca un huérfano, para
# que `git pull` de los usuarios avance en fast-forward.
#
# USO
#
#   scripts/publicar-espejo.sh                          # construye en ./.espejo
#   scripts/publicar-espejo.sh --rama estigmergia
#   scripts/publicar-espejo.sh --destino usuario@host:/var/www/motor
#
set -euo pipefail

RAMA="main"
SALIDA=""
DESTINO=""

while [ $# -gt 0 ]; do
    case "$1" in
        --rama)    RAMA="$2"; shift 2 ;;
        --salida)  SALIDA="$2"; shift 2 ;;
        --destino) DESTINO="$2"; shift 2 ;;
        -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
        *) echo "Opción desconocida: $1" >&2; exit 2 ;;
    esac
done

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SALIDA="${SALIDA:-$RAIZ/.espejo}"
DIST="$SALIDA/dist"
BARE="$SALIDA/azca-motor.git"

if ! git -C "$RAIZ" rev-parse --verify "$RAMA" >/dev/null 2>&1; then
    echo "No existe la rama '$RAMA' en $RAIZ" >&2
    exit 1
fi
COMMIT="$(git -C "$RAIZ" rev-parse --short "$RAMA")"
echo "Publicando $RAMA ($COMMIT) desde $RAIZ"

# El repositorio de distribución acumula un commit por publicación. Se crea la
# primera vez y se reutiliza después: es lo que mantiene el fast-forward.
if [ ! -d "$DIST/.git" ]; then
    echo "Creando el repositorio de distribución en $DIST"
    mkdir -p "$DIST"
    git -C "$DIST" init -q -b main
fi

# El árbol se reemplaza ENTERO en cada publicación: si sólo se copiara encima,
# un archivo borrado en el motor seguiría vivo en el espejo para siempre.
find "$DIST" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
git -C "$RAIZ" archive --format=tar "$RAMA" | tar -x -C "$DIST"

git -C "$DIST" add -A
if git -C "$DIST" diff --cached --quiet; then
    echo "El espejo ya está en $COMMIT: nada que publicar."
else
    git -C "$DIST" \
        -c user.name="Azca" -c user.email="axel@sintergica.ai" \
        commit -q -m "motor $COMMIT ($RAMA)"
    echo "Commit de distribución creado."
fi

# El repositorio servido es BARE: se sirve tal cual como ficheros estáticos.
if [ ! -d "$BARE" ]; then
    git clone -q --bare "$DIST" "$BARE"
else
    git -C "$BARE" fetch -q "$DIST" "main:main"
fi

# Sin esto el transporte estático no encuentra las referencias y el clon falla
# con «repository not found»: es el índice que git sirve cuando no hay servidor.
git -C "$BARE" update-server-info

echo "Espejo listo en $BARE ($(git -C "$BARE" rev-list --count main) versiones publicadas)"

if [ -n "$DESTINO" ]; then
    echo "Sincronizando con $DESTINO..."
    # --delete para que el destino sea un reflejo exacto; sin él quedarían
    # objetos sueltos de publicaciones anteriores acumulándose sin fin.
    rsync -az --delete "$BARE/" "$DESTINO/azca-motor.git/"
    echo "Publicado en $DESTINO"
else
    echo
    echo "Sin --destino no se sube nada. Para publicarlo:"
    echo "  rsync -az --delete \"$BARE/\" usuario@host:/var/www/motor/azca-motor.git/"
fi
