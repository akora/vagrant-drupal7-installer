#!/usr/bin/env bash

MySQL_config_file="/etc/mysql/my.cnf"
HOSTNAME=$(hostname -f)

echo "=== Installing MySQL server and setting root password..."
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get install -y mysql-client mysql-server

echo "=== Fixing warnings about changed setting names in $MySQL_config_file..."
if grep -Fxq "key_buffer_size" $MySQL_config_file
then
  echo "=== key_buffer_size found, nothing to do..."
else
  echo "=== Setting key_buffer_size..."
  sed -i 's/key_buffer/key_buffer_size/g' $MySQL_config_file
fi

if grep -Fxq "myisam-recover-options" $MySQL_config_file
then
  echo "=== myisam-recover-options found, nothing to do..."
else
  echo "=== Setting myisam-recover-options..."
  sed -i 's/myisam-recover/myisam-recover-options/g' $MySQL_config_file
fi

echo "=== Allowing remote management of MySQL server..."
if grep -Fxq "0.0.0.0" $MySQL_config_file
then
  echo "=== 0.0.0.0 found, nothing to do..."
else
  echo "=== Setting 0.0.0.0..."
  sed -i 's/127.0.0.1/0.0.0.0/g' $MySQL_config_file
fi

mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY 'root';"
mysql -uroot -proot -e "FLUSH PRIVILEGES;"

echo "=== Restarting service for changes to take effect..."
service mysql restart

echo "=== Installing Apache & PHP 5..."
apt-get install -y apache2 php5 libapache2-mod-php5 php5-mysql php5-mcrypt php5-gd php5-curl libssh2-php

echo "=== Installing local mail delivery capability..."
debconf-set-selections <<< "postfix postfix/mailname string vm01.vbox.local.dev"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -y postfix mailutils

echo "=== Enabling mod_rewrite & clean URLs..."
a2enmod rewrite
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

echo "=== Restarting service & removing default index.html..."
service apache2 restart
rm /var/www/html/index.html

echo "=== Installing Drupal 7 with Drush..."
cd ~
apt-get install drush -y
drush dl drupal-7
cd drupal*
rsync -avz . /var/www/html
cd /var/www/html
drush site-install minimal --site-name=D7 --account-name=admin --account-pass=admin --db-url=mysql://root:root@localhost/d7 --account-mail=vagrant@$HOSTNAME --site-mail=vagrant@$HOSTNAME -y

chmod 777 /var/www/html/sites/default/files/
chmod 777 /var/www/html/sites/all/modules/

mkdir /var/www/html/sites/default/private
chmod 777 /var/www/html/sites/default/private

chown -R vagrant /home/vagrant/.drush
chmod -R 777 /home/vagrant/.drush

echo "=== Making basic config changes and installing new modules with Drush..."
cd /var/www/html
drush en garland -y
drush vset theme_default garland
drush vset theme_admin garland
drush dl logintoboggan demo backup_migrate ctools views auto_nodetitle token features nodeformcols field_group node_save_redirect
drush en color field_ui locale menu path taxonomy backup_migrate logintoboggan views views_ui token -y
drush vset file_private_path sites/default/private -y
drush vset logintoboggan_login_with_email 1 -y
drush vset site_default_country "HU" -y
drush vset date_default_timezone "Europe/Budapest" -y
drush vset date_first_day 1 -y
drush vset configurable_timezones 0 -y
drush ev 'variable_set("theme_settings", array("toggle_logo" => "0"))'
drush cron

exit 0
