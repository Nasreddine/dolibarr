#!/bin/bash
# Script used by the Dockerfile.
# See README.md to know how to create a Dolibarr env with docker

if [ "${PHP_INI_DIR}" == "" ]; then
	echo
	echo This script must not be run directly. It is used by the Dockerfile
	echo See README.md
	echo
	exit
fi

usermod -u "${HOST_USER_ID}" www-data
groupmod -g "${HOST_GROUP_ID}" www-data

chgrp -hR www-data /var/www/html
chmod g+rwx /var/www/html/conf

if [ ! -d /var/www/documents ]; then
	echo "[docker-run] => create volume directory /var/www/documents ..."
	mkdir -p /var/www/documents
fi
echo "[docker-run] => Set Permission to www-data for /var/www/documents"
chown -R www-data:www-data /var/www/documents

# Create install.lock file for security
echo "[docker-run] => Creating install.lock file if it doesn't exist"
if [ ! -f /var/www/html/documents/install.lock ]; then
    touch /var/www/html/documents/install.lock
    chown www-data:www-data /var/www/html/documents/install.lock
    chmod 400 /var/www/html/documents/install.lock
fi

# Secure conf.php file if it exists
if [ -f /var/www/html/conf/conf.php ]; then
    echo "[docker-run] => Setting proper permissions on conf.php"
    chown www-data:www-data /var/www/html/conf/conf.php
    chmod 400 /var/www/html/conf/conf.php
fi

echo "[docker-run] => update '${PHP_INI_DIR}/conf.d/dolibarr-php.ini'"
cat <<EOF > "${PHP_INI_DIR}/conf.d/dolibarr-php.ini"
date.timezone = ${PHP_INI_DATE_TIMEZONE:-UTC}
memory_limit = ${PHP_INI_MEMORY_LIMIT:-256M}
EOF

cp /var/www/html/install/install.forced.docker.php /var/www/html/install/install.forced.php

exec apache2-foreground
