#!/bin/bash -eu
#********** Caution! **********
#Require WP-CLI
#Require root user
#******************************

#settings
DOMAIN_NAME=yourdomain.example.com
MARIADB_ROOT_USER_NAME=
MARIADB_ROOT_USER_PASSWD=
WP_DB_NAME=
WP_DB_USER=
WP_DB_PASSWD=
WP_PATH=
WP_TITLE=
WP_PLUGIN="wp-multibyte-patch advanced-custom-fields"

WP_ADMIN_USER=
WP_ADMIN_PASSWD=
WP_ADMIN_EMAIL=
DEVELOPER_LINUX_USER_NAME=
DEVELOPER_LINUX_GROUP_NAME=dev

#exectute
WP_DB_PASSWD=`cat /dev/urandom | tr -dc 'a-z' | fold -w 16 | head -n 1`
WP_DB_PREFIX=`cat /dev/urandom | tr -dc 'a-z' | fold -w 8 | head -n 1`

echo "*********************************"
echo "Make directory"
echo "*********************************"
cd /var/www/html/
mkdir "${DOMAIN_NAME}"
chmod 2775 "${DOMAIN_NAME}"
cd "${DOMAIN_NAME}"
echo "*********************************"
echo "MariaDB (MySQL)"
echo "*********************************"
mysql -u"${MARIADB_ROOT_USER_NAME}" -p"${MARIADB_ROOT_USER_PASSWD}" -e "create database ${WP_DB_NAME}"
mysql -u"${MARIADB_ROOT_USER_NAME}" -p"${MARIADB_ROOT_USER_PASSWD}" -e "grant all privileges on ${WP_DB_NAME}.* to ${WP_DB_USER}@localhost identified by "\""${WP_DB_PASSWD}"\"";"

echo "*********************************"
echo "WordPress (WP-CLI)"
echo "*********************************"
wp core download --locale=ja --path="/var/www/html/${DOMAIN_NAME}/${WP_PATH}" --allow-root
cd "${WP_PATH}"
wp core config --path="/var/www/html/${DOMAIN_NAME}/${WP_PATH}" --dbname="${WP_DB_NAME}" --dbuser="${WP_DB_USER}" --dbpass="${WP_DB_PASSWD}" --dbprefix="${WP_DB_PREFIX}_" --allow-root
wp core install --path="/var/www/html/${DOMAIN_NAME}/${WP_PATH}" --url="https://${DOMAIN_NAME}/" --title="${WP_TITLE}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASSWD}" --admin_email="${WP_ADMIN_EMAIL}" --allow-root
wp option update siteurl "https://${DOMAIN_NAME}/${WP_PATH}" --allow-root
cp index.php ../index.php
sed -i -e "s/wp-blog-header.php/${WP_PATH}\/wp-blog-header.php/g" ../index.php

echo "*********************************"
echo "WordPress oprion"
echo "*********************************"
wp option update blog_public 1 --allow-root
wp option update default_comment_status closed --allow-root
wp option update default_ping_status closed --allow-root
wp option update default_pingback_flag "" --allow-root
wp rewrite structure /%category%/%postname%/ --allow-root

echo "*********************************"
echo "Plugins"
echo "*********************************"
for i in "${WP_PLUGIN[@]}"; do
	wp plugin install "${i}" --allow-root
	wp plugin activate "${i}" --allow-root
done
chown -R apache:apache ./wp-content/plugins/

echo "*********************************"
echo "Delete sample page"
echo "*********************************"
wp post delete 1 2 --allow-root

echo "*********************************"
echo ".htaccess"
echo "*********************************"
cat <<EOF > ".htaccess"
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteCond %{HTTPS} off
  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
  RewriteRule ^index\.php$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.php [L]
</IfModule>
EOF

echo "*********************************"
echo "Directory permission"
echo "*********************************"
rm -rf ./"${WP_PATH}"/wp-content/themes/twenty*
chown -R "${DEVELOPER_LINUX_USER_NAME}":"${DEVELOPER_LINUX_GROUP_NAME}" ./
chown -R apache:"${DEVELOPER_LINUX_GROUP_NAME}" ./"${WP_PATH}"
find ./"${WP_PATH}"/ -type f -exec chmod 664 \{\} \;
find ./"${WP_PATH}"/ -type d -exec chmod 2775 \{\} \;
chown apache. .htaccess
chmod 440 .htaccess
chmod 440 ./"${WP_PATH}"/wp-config.php

echo "*********************************"
echo "Apache VirtualHost"
echo "*********************************"
cd /etc/httpd/conf.d/
cat <<EOF > "virtualhost-${DOMAIN_NAME}.conf"
<VirtualHost *:80>
    ServerName ${DOMAIN_NAME}
    DocumentRoot /var/www/html/${DOMAIN_NAME}
    ErrorLog logs/${DOMAIN_NAME}-error_log
    CustomLog logs/${DOMAIN_NAME}-access_log combined env=!no_log
    DirectoryIndex index.php index.html
  <Directory "/var/www/html/${DOMAIN_NAME}">
    Options FollowSymLinks
    AllowOverride all
  </Directory>
</VirtualHost>

<VirtualHost *:443>
  DocumentRoot /var/www/html/${DOMAIN_NAME}
  ServerName ${DOMAIN_NAME}
  ErrorLog logs/${DOMAIN_NAME}-ssl-error_log
  CustomLog logs/${DOMAIN_NAME}-ssl-access_log combined
  DirectoryIndex index.php index.html

  <Directory "/var/www/html/${DOMAIN_NAME}">
    Options FollowSymLinks
    AllowOverride all
  </Directory>

  TransferLog logs/${DOMAIN_NAME}-ssl_access_log
  LogLevel warn

  SSLEngine on
  SSLProtocol -ALL +TLSv1 +TLSv1.1 +TLSv1.2
  SSLHonorCipherOrder On
  SSLCipherSuite EECDH+AESGCM+AES128:EECDH+AESGCM:EECDH+AES128:EECDH+AES256
  SSLCertificateFile /etc/pki/tls/certs/${CERT_FILE_NAME}
  SSLCertificateKeyFile /etc/pki/tls/certs/${KEY_FILE_NAME}
  SSLCertificateChainFile /etc/pki/tls/certs/${CA_FILE_NAME}

  <Files ~ "\.(cgi|shtml|phtml|php3?)$">
    SSLOptions +StdEnvVars
  </Files>
  <Directory "/var/www/cgi-bin">
    SSLOptions +StdEnvVars
  </Directory>
  CustomLog logs/ssl_request_log \
  "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
</VirtualHost>
EOF
echo "*********************************"
echo "apache configtest"
echo "*********************************"
apachectl configtest
echo "↑If Syntax OK then Restart Apache. Be carefull"
echo "*********************************"
echo "Done ${DOMAIN_NAME}"
