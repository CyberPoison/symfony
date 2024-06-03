FROM ubuntu:latest

# Install prerequisites
RUN apt-get update \
    && apt-get install -y software-properties-common

# Add Ondřej Surý's PPA
RUN add-apt-repository ppa:ondrej/php \
    && apt-get update

# Install Apache2, PHP 8.2, SSH/SFTP, MySQL, phpMyAdmin, and other dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apache2 \
        php8.2 \
        libapache2-mod-php8.2 \
        php8.2-cli \
        php8.2-mysql \
        php8.2-curl \
        php8.2-gd \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        php8.2-intl \
        php8.2-exif \
        php8.2-pdo \
        php8.2-pdo-mysql \
        php8.2-bcmath \
        php8.2-apcu \
        php8.2-opcache \
        php8.2-dba \
        php8.2-bz2 \
        php8.2-gmp \
        php8.2-imagick \
        php8.2-imap \
        php8.2-memcached \
        php8.2-pspell \
        php8.2-redis \
        php8.2-soap \
        php8.2-sqlite3 \
        php8.2-xml \
        php8.2-fpm \
        openssh-server \
        vim \
        pwgen \
        mysql-server \
        phpmyadmin \
        cron \
        rsync \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable PHP modules/extensions
RUN phpenmod -v 8.2 dba bz2 gmp imagick imap memcached pspell redis soap sqlite3 xml gd zip curl simplexml


# Enable PHP FPM
RUN a2enconf php8.2-fpm

# Enable SSH/SFTP
RUN mkdir /var/run/sshd

# Update MySQL configuration file to point to the new data directory and socket location
RUN sed -i '/^# datadir\s*=/s/^# //' /etc/mysql/mysql.conf.d/mysqld.cnf && \
    sed -i 's|/var/lib/mysql|/mnt/mysql|' /etc/mysql/mysql.conf.d/mysqld.cnf

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# Configure cron
RUN service cron start

# Configure Apache2 for phpMyAdmin
RUN echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
RUN echo "Alias /phpmyadminFYUBN3uY /usr/share/phpmyadmin" >> /etc/apache2/apache2.conf
RUN echo "<Directory /usr/share/phpmyadmin>" >> /etc/apache2/apache2.conf
RUN echo "    Options Indexes FollowSymLinks" >> /etc/apache2/apache2.conf
RUN echo "    DirectoryIndex index.php" >> /etc/apache2/apache2.conf
RUN echo "    AllowOverride All" >> /etc/apache2/apache2.conf
RUN echo "</Directory>" >> /etc/apache2/apache2.conf

# Copy the setup_ssh.sh script into the container
COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

# Expose SSH/SFTP, Apache2, MySQL, and phpMyAdmin ports
EXPOSE 22 80 3306

# Run the setup_ssh.sh script when the container starts
CMD ["start.sh"]
