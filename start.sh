#!/bin/bash

# Check if SSH_PASSWORD environment variable is set
# If not set, generate a random password for root user
if [ -z "$SSH_PASSWORD" ]; then
    SSH_PASSWORD=$(pwgen -s 12 1)
fi
if [ -z "$PHPMYADMIN_PASSWORD" ]; then
    PHPMYADMIN_PASSWORD=$(pwgen -s1 32)
fi
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    MYSQL_ROOT_PASSWORD=$(pwgen -s 12 1)
fi
if [ -z "$WWW_DATA_PASSWORD" ]; then
    WWW_DATA_PASSWORD=$(pwgen -s 12 1)
fi

# Define php8.2 as default
update-alternatives --set php /usr/bin/php8.2

service mysql start
service cron start # Start cron service

# Set MySQL root password
echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

# Check if the phpMyAdmin database and user exist, create them if not
mysql -u root -e "CREATE DATABASE IF NOT EXISTS phpmyadmin;"
mysql -u root -e "CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '${PHPMYADMIN_PASSWORD}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

# Update phpMyAdmin config-db.php file with the new password and server configuration
sed -i "s/\$dbpass='[^']*';/\$dbpass='${PHPMYADMIN_PASSWORD}';/" /etc/phpmyadmin/config-db.php
sed -i "s/\$dbserver='localhost';/\$dbserver='127.0.0.1';/" /etc/phpmyadmin/config-db.php

# Define Password for root and www-data
echo "root:$SSH_PASSWORD" | chpasswd
echo "www-data:$WWW_DATA_PASSWORD" | chpasswd
echo "Root password: $SSH_PASSWORD"
echo "www-data password: $WWW_DATA_PASSWORD"
echo "Phpmyadmin password: $PHPMYADMIN_PASSWORD"
echo "Mysql root password: $MYSQL_ROOT_PASSWORD"

# Write crontab commands to a file
echo "0 11 * * *  php8.2 /var/www/html/bin/console app:google:update-budget" > /tmp/cron_commands
echo "0 */12 * * * php8.2 /var/www/html/bin/console app:google:auth --refresh" >> /tmp/cron_commands

# Copy the file to www-data user's crontab
crontab -u www-data /tmp/cron_commands

# Remove the temporary file
rm /tmp/cron_commands

# Set interactive shell for www-data
chsh -s /bin/bash www-data

# Allow www-data user to login via SSH
echo "AllowUsers www-data" >> /etc/ssh/sshd_config

# Restart SSH service
service sshd restart

# Start Apache2 and SSH services
service apache2 start
/usr/sbin/sshd -D
