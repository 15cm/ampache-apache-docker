#!/bin/bash

example_conf_file=/var/www/html/config/ampache.cfg.php.dist
php_conf_dir=/usr/local/etc/php

# Set timezone
unlink /etc/localtime
ln -s /usr/share/zoneinfo/${TZ} /etc/localtime

# Crontab job to update catalogs
# ATTENTION: duplicated tracks can be added when the catalogs are updated by both the web UI and CLI
# Such updates can insert two records of a same track one after another by two different users: you(e.g. "admin") for web and "admin" for CLI
# A lock for catalogs updating in Ampache should solve this problem
# Here I choose to let the user specify the crontab rule of updating to make sure the catalogs are first updated by web UI once
# and then by CLI periodically so that the race condition won't happen
[ -n "${CRON_JOB_UPDATE_CATALOGS}" ] && (crontab -l 2>/dev/null; echo "${CRON_JOB_UPDATE_CATALOGS} /usr/local/bin/php /var/www/html/bin/catalog_update.inc -cagm") | sort | uniq | crontab -
service cron restart

# Apply ENV Vars
if [ -f ${example_conf_file} ]; then
sudo -u www-data [ -n "${MEMORY_CACHE_ENABLED}" ] && sed -i 's|;*\s*\(memory_cache = \).*|\1"true"|' ${example_conf_file}
sudo -u www-data sed -i "s|;*\s*\(memory_limit = \).*|\1\"${MEMORY_LIMIT:-32}\"|" ${example_conf_file}
sudo -u www-data [ -n "${LOCAL_WEB_PATH}" ] && sed -i "s|;*\s*\(local_web_path = \).*|\1\"${LOCAL_WEB_PATH}\"|" ${example_conf_file}
sudo -u www-data [ -n "${ART_ORDER}" ] && sed -i "s|;*\s*\(art_order = \).*|\1\"${ART_ORDER}\"|" ${example_conf_file}
sudo -u www-data [ -n "${LASTFM_API_KEY}" ] && sed -i "s|;*\s*\(lastfm_api_key = \).*|\1\"${LASTFM_API_KEY}\"|" ${example_conf_file}
sudo -u www-data [ -n "${LASTFM_API_SECRET}" ] && sed -i "s|;*\s*\(lastfm_api_secret = \).*|\1\"${LASTFM_API_SECRET}\"|" ${example_conf_file}
fi

# Modify php settings
cp ${php_conf_dir}/php.ini-production ${php_conf_dir}/php.ini
sed -i "s|;*\s*\(memory_limit = \).*|\1\"${MEMORY_LIMIT:-32}\"M|" ${php_conf_dir}/php.ini

# run this in the foreground so Docker won't exit
exec /usr/local/bin/apache2-foreground
