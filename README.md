# ampache-apache

Docker container for [Ampache](http://ampache.org), a web based audio/video
streaming application and file manager allowing you to access your music &
videos from anywhere, using almost any internet enabled device.

This image ships ampache on top of mod_php on Apache. It is listening on
port 80. It does not come with a database. It is suggested that you install a
separate container (for instance [the official
mariadb](https://hub.docker.com/_/mariadb/) image) and then either `--link` the
container or put it on the same docker network as the ampache container. Then
you can connect to it from your ampache container.

## Quick usage

### docker run

```bash
docker run --name ampache \
-e CRON_JOB_UPDATE_CATALOGS=0 4 * * * \
-e TZ=America/New_York \
-e MEMORY_CACHE_ENABLED=true \
-e MEMORY_LIMIT=1024 \
-e LOCAL_WEB_PATH=https://yourdomain.com \
-v /config:/var/www/html/config \
-v /music:/media \
-p 8080:80 \
15cm/ampache-apache-docker
```

Then visit the container in a web browser to complete the setup. When prompted
for database, provide the credentials for the database you `--link`ed or that
is on the same network (using the link name, or the name of the database
container as the hostname).

### docker-compose

`docker-compose` is recommended to run this docker image along with the mariadb
image. Clone the git repository from
<https://github.com/15cm/ampache-apache-docker>, check the ENV variables in
`./mariadb.env`, `./ampache.env` and mount volumes in `./docker-compose.yml`.
Then run `docker-compose up` under the repository directory.

## Image details

The image is based upon the upstream `php` image (7.1 on Debian stretch at the
moment). It exposes ampache (via apache and mod_php) on port `80`. If you want
to run it on https (or run several webapps on the same host), you can achieve
this by having a reverse proxy in front of it. The
[nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy/) container paired
with
[letsencrypt-nginx-proxy-companion](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion/)
works great along with this container and is simple to set up.
[traefik](https://github.com/containous/traefik) is also a good tool to automate
your reverse proxy configurations.

## Volumes

All of these are marked as a volume by default.

`/media` is the suggested location to mount your music collection to. This can
be read-only.

`/var/www/html/config` is where the config files reside.

`/var/www/html/themes` is where custom themes reside. You only need to worry
about this one if you actually want to use custom themes.

## Ampache configuration

To avoid editing `/var/www/html/config/ampache.cfg.php` by hand. Some ENV
variables are provided to setup the Ampache instance:
- `MEMORY_CACHE_ENABLED=true`
- `MEMORY_LIMIT=1024`
- `LOCAL_WEB_PATH=https://yourdomain.com`

The meaning of these options can be checked at <https://github.com/ampache/ampache/blob/develop/config/ampache.cfg.php.dist>.

## Auto-updating the library

It seems that Ampache doesn't have a lock for the library to prevent race
condition when updating catalogs with web UI and CLI simultaneously. These two
UI updates the catalogs using two different user, e.g., "admin" and "ampache"
separately, resulting in duplicated track insertion. Therefore instead of using
inotify to watch the library, this docker image use crontab to update the
library periodically.

Set the `CRON_JOB_UPDATE_CATALOGS` ENV variable with crontab rule like `0
0 * * *` to auto-update all catalogs. Please make sure you won't update the
library manually via the web UI when the crontab job is running.

A timezone ENV variable `TZ` is also provided to ensure the crontab job runs
with your local time.

## Thanks to
- @arielelkin for the initial work on this container
- @ericfrederich for his original work
- @velocity303 and @goldy for the other ampache-docker inspiration
