#!/usr/bin/env bash

echo "=== Installing missing system components..."
sudo apt-get install -y zip unzip

echo "=== Installing Composer..."
cd ~
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

echo "=== Installing modules for SendGrid integration..."
cd /var/www/html
sudo chmod 777 /home/vagrant/.drush/cache/default # fixing Drush
drush dl xautoload mailsystem sendgrid_integration -y
drush en xautoload -y

echo "=== Enabling SendGrid integration..."
cd sites/all/modules/sendgrid_integration/
composer install # installing wrapper
cd /var/www/html
drush en mailsystem sendgrid_integration -y

exit 0
