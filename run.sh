#!/bin/bash

example_conf_file=/var/www/html/config/ampache.cfg.php.dist

# Update the .dist file in the volume, so that we *KNOW* that it is up-to-date
# with the ampache version
sudo -u www-data cp /ampache.cfg.php.dist ${example_conf_file}

# Crontab job to update catalogs
# ATTENTION: duplicated tracks can be added when the catalogs are updated by both the web UI and CLI
# Such updates can insert two records of a same track one after another by two different users: you(e.g. "admin") for web and "admin" for CLI
# A lock for catalogs updating in Ampache should solve this problem
# Here I choose to let the user specify the crontab rule of updating to make sure the catalogs are first updated by web UI once
# and then by CLI periodically so that the race condition won't happen
[ -n "${CRON_JOB_UPDATE_CATALOGS}" ] && (crontab -l 2>/dev/null; echo "${CRON_JOB_UPDATE_CATALOGS} php /var/www/html/bin/catalog_update.inc") | sort | uniq | crontab -
service cron start
service cron reload


# run this in the foreground so Docker won't exit
exec /usr/local/bin/apache2-foreground
