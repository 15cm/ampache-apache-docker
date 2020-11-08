FROM php:7.3-apache-stretch
LABEL maintainer="Eskild Hustvedt code@zerodogg.org"

# The ampache version
ARG version=4.2.4
# The composer version
ARG composerVersion=1.6.5

    # Fetch apt repo metadata
RUN apt-get update && \
    # Install debs needed to add the VLC repo
    DEBIAN_FRONTEND=noninteractive apt-get -y install wget sudo gnupg2 && \
    # Add the VLC repo to get up-to-date codecs
    echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list && \
    echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list && \
    wget --progress=bar:force:noscroll -O - https://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add - && \
    apt-get update && \
    # Install libraries/codecs and tools that ampache needs
    DEBIAN_FRONTEND=noninteractive apt-get -y install lame libvorbisfile3 libvorbisenc2 vorbis-tools flac libmp3lame0 libavcodec-extra* libtheora0 libvpx4 libav-tools git libpng-dev libjpeg-dev libfreetype6-dev libjpeg62-turbo libxml2 libxml2-dev && \
    # Install core PHP extensions (GD+MySQL)
    docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr && \
    docker-php-ext-install pdo_mysql gd && \
    # Install secondary extensions needed for UPNP
    CFLAGS="-I/usr/src/php" docker-php-ext-install sockets xmlreader

    # Download, extract and install ampache
RUN wget --progress=bar:force:noscroll -O /opt/ampache.tar.gz https://github.com/ampache/ampache/archive/$version.tar.gz && \
    rm -rf /var/www/html/* && \
    tar -C /var/www/html/ -xf /opt/ampache.tar.gz ampache-$version --strip=1 && \
    # Fix ownership
    chown -R www-data /var/www/html/

    # Install composer (used to install PHP library dependencies)
RUN wget --progress=bar:force:noscroll -O /usr/local/bin/composer "https://github.com/composer/getcomposer.org/raw/HEAD/web/download/$composerVersion/composer.phar" && \
    chmod 755 /usr/local/bin/composer && \
    # Install dependencies with composer
    cd /var/www/html && sudo -u www-data composer install --prefer-source --no-interaction --optimize-autoloader && \
    # Remove composer
    rm -f /usr/local/bin/composer

    # Config
    # Remove git repo data that we don't need
RUN find /var/www/html/lib/vendor -name .git -type d -print0 |xargs -0 -- rm -rf && \
    # Move all the htaccess files into place
    for dir in $(find /var/www/html -name .htaccess.dist -print0|xargs -0 dirname); do cp $dir/.htaccess.dist $dir/.htaccess;done && \
    # Enable mod_rewrite
    ln -sf /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load && \
    # Modify the .dist config:
    # - comment out database_name and database_username by default
    # - set the default database_hostname to "mysql"
    perl -pi -E 's{^(database_username|database_name)}{;$1}g; s{^database_hostname\s*=.*}{database_hostname = mysql}' /var/www/html/config/ampache.cfg.php.dist

    # Misc packages
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install cron

    # Clean up
RUN apt-get clean && \
    DEBIAN_FRONTEND=noninteractive apt-get -y purge libpng-dev libjpeg-dev libfreetype6-dev libxml2-dev && \
    rm -rf /var/lib/apt/lists/*
RUN rm -f /opt/ampache.tar.gz && \
    DEBIAN_FRONTEND=noninteractive apt-get -y purge --auto-remove g++-6 gcc-6 dpkg-dev libc6-dev libgcc-6-dev libstdc++-6-dev linux-libc-dev zlib1g-dev libc-dev-bin

ADD run.sh /run.sh
RUN chmod a+x /run.sh


VOLUME ["/media"]
VOLUME ["/var/www/html/config"]
VOLUME ["/var/www/html/themes"]
EXPOSE 80

CMD ["/run.sh"]
