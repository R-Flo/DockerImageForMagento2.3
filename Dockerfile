FROM php:7.2-apache

MAINTAINER IDMKR <contact@idmkr.io>

ENV XDEBUG_PORT 9000

RUN apt-get update \
  && apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libxslt1-dev \
    git \
    vim \
    wget \
    lynx \
    psmisc \
    libssl-dev \
	libedit2 \
	libxslt1-dev \
	apt-utils \
	gnupg \
	redis-tools \
	curl \
	unzip \
	tar \
	cron \
	bash-completion \
  && apt-get clean

RUN docker-php-ext-configure \
    gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/; \
  docker-php-ext-install \
    gd \
    intl \
    mbstring \
    pdo_mysql \
    xsl \
    zip \
    opcache \
    bcmath \
    soap


RUN apt-get update -y && \
    apt-get install -y libmcrypt-dev && \
    pecl install mcrypt-1.0.1 && \
    docker-php-ext-enable mcrypt


RUN wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz \
    && tar xfvz libsodium-1.0.18.tar.gz \
    && cd libsodium-1.0.18 \
    && ./configure \
    && make && make install \
    # && pecl install -f libsodium

# Install oAuth

RUN apt-get update \
  	&& apt-get install -y \
  	libpcre3 \
  	libpcre3-dev \
  	# php-pear \
  	&& pecl install oauth \
  	&& echo "extension=oauth.so" > /usr/local/etc/php/conf.d/docker-php-ext-oauth.ini

# Install Node, NVM, NPM and Grunt

#RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
#  	&& apt-get install -y nodejs build-essential \
#    && curl https://raw.githubusercontent.com/creationix/nvm/v0.16.1/install.sh | sh \
#    && npm i -g grunt-cli yarn

RUN apt install nodejs -y \
    && apt install npm -y \
    && npm i -g grunt-cli yarn


# Install Composer

RUN	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
RUN composer global require hirak/prestissimo

# Install Code Sniffer

RUN git clone https://github.com/magento/marketplace-eqp.git ~/.composer/vendor/magento/marketplace-eqp
RUN cd ~/.composer/vendor/magento/marketplace-eqp && composer install
RUN ln -s ~/.composer/vendor/magento/marketplace-eqp/vendor/bin/phpcs /usr/local/bin;

ENV PATH="/var/www/.composer/vendor/bin/:${PATH}"

# Install XDebug

RUN yes | pecl install xdebug && \
	 echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.iniOLD

# Install Mhsendmail

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install golang-go \
   && mkdir /opt/go \
   && export GOPATH=/opt/go \
   && go get github.com/mailhog/mhsendmail


ADD .docker/config/custom-xdebug.ini /usr/local/etc/php/conf.d/custom-xdebug.ini
COPY .docker/bin/* /usr/local/bin/
COPY .docker/users/* /var/www/
RUN chmod +x /usr/local/bin/*

ADD https://raw.githubusercontent.com/colinmollenhour/credis/master/Client.php /credis.php
ADD php.ini /usr/local/etc/php/conf.d/888-fballiano.ini
ADD register-host-on-redis.php /register-host-on-redis.php
ADD unregister-host-on-redis.php /unregister-host-on-redis.php
ADD start.sh /start.sh

RUN usermod -u 1000 www-data; \
  a2enmod rewrite; \
  curl -o /tmp/composer-setup.php https://getcomposer.org/installer; \
  curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig; \
  php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"; \
  php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer; \
	rm /tmp/composer-setup.php; \
  chmod +x /usr/local/bin/composer; \
  curl -o n98-magerun2.phar http://files.magerun.net/n98-magerun2-latest.phar; \
  chmod +x ./n98-magerun2.phar; \
  chmod +x /start.sh; \
  chmod +r /credis.php; \
  mv n98-magerun2.phar /usr/local/bin/; \
  mkdir -p /root/.composer

RUN curl -o /etc/bash_completion.d/m2install-bash-completion https://raw.githubusercontent.com/yvoronoy/m2install/master/m2install-bash-completion
RUN curl -o /etc/bash_completion.d/n98-magerun2.phar.bash https://raw.githubusercontent.com/netz98/n98-magerun2/master/res/autocompletion/bash/n98-magerun2.phar.bash
RUN echo "source /etc/bash_completion" >> /root/.bashrc
RUN echo "source /etc/bash_completion" >> /var/www/.bashrc

CMD ["/start.sh"]

