# hadolint ignore=DL3007
FROM php:7.3-apache-stretch

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG NVM_VERSION="v0.34.0"
ARG INSTALLATION_DIRECTORY="/home/thunder/www"
ARG THUNDER_TEST_GROUP="Thunder_Base_Set"
ARG PROFILE="thunder"

# Install required libraries and packages for running Drupal.
RUN set -xe; \
    \
    apt-get update; \
    \
    apt-get install -y --no-install-recommends \
        git \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        sudo \
    ; \
    \
    docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr \
        --with-jpeg-dir=/usr \
        --with-png-dir=/usr \
    ; \
    \
    docker-php-ext-install \
        gd \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        zip \
    ; \
    \
    apt list --installed | grep -o '.*-dev' | xargs apt-get purge -y; \
    \
    apt-get clean; \
    \
    rm -rf /var/lib/apt/lists/*; \
    \
    /usr/sbin/a2enmod rewrite;

# Setup PHP Cli OpCache
RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.enable_cli=1'; \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=10000'; \
		echo 'opcache.validate_timestamps=0'; \
		echo 'opcache.fast_shutdown=1'; \
	} >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini; \
    \
    { \
        echo 'memory_limit=512M'; \
    } >> /usr/local/etc/php/conf.d/z-custom.ini;

# Create required user - add to sudoers so that the thunder user can run Apache.
RUN set -xe; \
    \
    adduser --gecos "" --disabled-password thunder; \
    \
    usermod --append --groups sudo thunder; \
    \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers ;

# Install required libraries and packages
# hadolint ignore=DL3008
RUN set -xe; \
    \
    apt-get update; \
    \
    apt-get install --yes --no-install-recommends gnupg apt-transport-https netcat unzip mysql-client; \
    \
    curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - ; \
    \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list; \
    \
    apt-get update; \
    \
    apt-get install --yes --no-install-recommends yarn; \
    \
    su - thunder --command="curl -o- https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh | bash"; \
    \
    echo -e "\nexport NVM_DIR=\"\$HOME/.nvm\"\n[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"\n" >> /home/thunder/.profile; \
    \
    su - thunder --command="nvm install --lts node"; \
    \
    su - thunder --command="npm config set update-notifier false"; \
    \
    dpkg --get-selections | grep --only-matching '.*-dev' | xargs apt-get purge --yes; \
    \
    apt-get purge --yes gnupg apt-transport-https; \
    \
    apt-get clean; \
    \
    rm --recursive --force /var/lib/apt/lists/*;

# Copy code to container
COPY --chown=thunder:thunder www ${INSTALLATION_DIRECTORY}

# Unfortunately this doesn't quite work as expected.
# ENV APACHE_RUN_USER=thunder

# Copy run scripts
COPY scripts/docker/* /usr/local/bin/

# Set the scripts to be executable. Create a link to thunder-php-test as this is
# name expected by the runner.
ENV INSTALLATION_DIRECTORY=${INSTALLATION_DIRECTORY}
RUN set -xe; \
    \
    echo -e "\nexport PATH=\"\$PATH:${INSTALLATION_DIRECTORY}/bin:${INSTALLATION_DIRECTORY}/vendor/bin\"\n" >> /home/thunder/.profile; \
    \
    chmod +x /usr/local/bin/drupal-php-install; \
    \
    chmod +x /usr/local/bin/drupal-php-test; \
    \
    chmod +x /usr/local/bin/drupal-php-run; \
    \
    chmod +x /usr/local/bin/set-docroot; \
    \
    chmod +x /usr/local/bin/install-elastic-apm; \
    \
    ln -sfn /usr/local/bin/drupal-php-test /usr/local/bin/thunder-php-test; \
    \
    set-docroot; \
    \
    cat /home/thunder/.profile;

# Install Elastic APM - this is run as a shell script so we can install in the
# doc root.
RUN set -xe; \
    \
    su - thunder --command="install-elastic-apm";

# Provision core tests
# @todo move this to one of our modules only work with core checkout atm.
RUN set -xe; \
    \
    mkdir -p ${INSTALLATION_DIRECTORY}/modules/contrib/testsite_builder/tests;

COPY --chown=thunder:thunder coretests ${INSTALLATION_DIRECTORY}/modules/contrib/testsite_builder/tests

# Define all runtime environments
ENV DB_HOST="127.0.0.1"
ENV DB_NAME="thunder"
ENV DB_USER="thunder"
ENV DB_PASS="thunder"
ENV DB_PORT="3306"
ENV DB_DIVER="mysql"

# Test related environment variables
ENV THUNDER_HOST="localhost"
ENV CHROME_HOST="localhost"
ENV THUNDER_TEST_SITE_TEMPLATE="https://raw.githubusercontent.com/thunder/thunder-performance-site-templates/master/thunder_base_set.json"
ENV THUNDER_TEST_GROUP=${THUNDER_TEST_GROUP}
ENV PROFILE=${PROFILE}

# Elastic APM integration environments variables
ENV ELASTIC_APM_URL="http://127.0.0.1:8200"
ENV ELASTIC_APM_CONTEXT_TAG_BRANCH="master"

EXPOSE 80/tcp
CMD ["bash", "-x", "drupal-php-run"]
