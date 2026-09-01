# Espejo del motor

Sirve el motor de Azca a los usuarios finales desde dominio propio, para que el
escritorio pueda instalarlo sin que este repositorio deje de ser privado.

## Por qué existe

El escritorio instala el motor con un `git clone` **anónimo**. Este repositorio
es privado, así que un clon directo devuelve 404 — la misma restricción que
obligó a que `azca-registro` fuera público. El espejo es una copia de sólo
lectura, servida por el Caddy que ya corre en `consola.sintergica.ai`.

Tres decisiones, todas medidas:

**Se publica como repositorio git, no como tarball.** `hermes update` y la rama
de actualización del propio instalador trabajan sobre un checkout de git. Un
tarball dejaría a los usuarios instalados sin ninguna vía de actualización del
motor.

**Se publica aplastado, un commit por versión.** Un repositorio servido como
ficheros estáticos usa el transporte «tonto» de git, que aborta ante `--depth`
con `dumb http transport does not support shallow capabilities`. Sin clon
superficial, servir el historial entero obligaría a cada usuario a descargar
650 MB. Aplastado, el espejo pesa **185 MB** y el clon completo tarda unos
13 segundos en local.

**No hace falta un servidor git inteligente.** Con el aplastado, un
`file_server` estático basta, y eso es exactamente lo que Caddy ya sabe hacer
sin plugins ni CGI.

## Publicar

Desde este repositorio:

```bash
scripts/publicar-espejo.sh --destino usuario@consola.sintergica.ai:/var/www/motor
```

Construye el espejo en `.espejo/` y lo sincroniza. Cada publicación es un
commit **encima** de la anterior, nunca un huérfano, para que el `git pull` de
los usuarios ya instalados avance en fast-forward.

Sin `--destino` sólo construye en local, que es lo que conviene para revisar
qué se va a publicar antes de subirlo.

## Servir

En el servidor, una vez:

```bash
sudo mkdir -p /var/www/motor
sudo chown "$USER" /var/www/motor
```

Y en el Caddyfile, dentro del bloque de `consola.sintergica.ai`:

```caddyfile
handle_path /motor/* {
    root * /var/www/motor
    file_server
}
```

El `handle_path` quita el prefijo `/motor` antes de resolver el fichero, así
que `https://consola.sintergica.ai/motor/azca-motor.git/info/refs` cae en
`/var/www/motor/azca-motor.git/info/refs`, que es lo que git pide.

Los dos scripts de instalación se sirven del mismo sitio:

```bash
rsync -a scripts/install.sh scripts/install.ps1 \
    usuario@consola.sintergica.ai:/var/www/motor/
```

## Apuntar el escritorio

En el `.env` de la compilación de `kana-desktop`:

```
KANA_ENGINE_INSTALL_BASE=https://consola.sintergica.ai/motor
KANA_ENGINE_GIT_URL=https://consola.sintergica.ai/motor/azca-motor.git
```

La primera manda de dónde se bajan `install.sh` / `install.ps1`; la segunda
viaja al script como `HERMES_REPO_URL` y es la que redirige el clon. Sin ellas
el escritorio sigue instalando el motor del upstream, que es el comportamiento
por omisión.

## Comprobar que quedó bien

```bash
git clone https://consola.sintergica.ai/motor/azca-motor.git /tmp/motor-prueba
```

Si eso funciona desde una máquina sin credenciales, el circuito está completo.
Si falla con «repository not found», falta `git update-server-info` en el
destino — el publicador lo corre, pero un `rsync` a mano se lo puede saltar.

## Lo que este espejo no oculta

El código del motor queda descargable por cualquiera que conozca la URL, y la
URL viaja dentro de la aplicación. Esto no es un fallo de esta receta: **es
inherente a distribuir un motor escrito en Python**, y pasa igual empaquetándolo
dentro del `.app`. Lo que el espejo sí evita es que el repositorio esté listado,
indexado y clonable desde GitHub con su historial y sus ramas de trabajo.
