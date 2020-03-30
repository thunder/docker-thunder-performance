# hadolint ignore=DL3007
FROM burda/thunder-php:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG NVM_VERSION="v0.34.0"
ARG COMPOSER_ROOT_VERSION="8.8.3"
ARG INSTALLATION_DIRECTORY="/home/thunder/www"
ARG COMPOSER_AUTH
ARG THUNDER_TEST_GROUP="Thunder_Base_Set"
ARG PROFILE="thunder"

# Create required user
RUN set -xe; \
    \
    adduser --gecos "" --disabled-password thunder; \
    \
    usermod --append --groups sudo thunder;

# Install required libraries and packages
# hadolint ignore=DL3008
RUN set -xe; \
    \
    apt-get update; \
    \
    apt-get install --yes --no-install-recommends gnupg apt-transport-https netcat unzip; \
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

# Copy run scripts
COPY scripts/docker/* /usr/local/bin/

# Set executable
RUN set -xe; \
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
    ln -sfn /usr/local/bin/drupal-php-run /usr/local/bin/thunder-php-run;

# Copy pre-build Thunder project to container
COPY --chown=thunder:thunder www ${INSTALLATION_DIRECTORY}

# Set DOC_ROOT environment var
ENV INSTALLATION_DIRECTORY=${INSTALLATION_DIRECTORY}
RUN set -xe; \
    \
    set-docroot; \
    \
    cat /home/thunder/.profile;

# Build codebase.
RUN set -xe; \
    \
    su - thunder --command="cd ${INSTALLATION_DIRECTORY}; COMPOSER_MEMORY_LIMIT=-1 COMPOSER_AUTH='${COMPOSER_AUTH}' COMPOSER_ROOT_VERSION=${COMPOSER_ROOT_VERSION} composer install --no-dev"; \
    \
    su - thunder --command="cd ${INSTALLATION_DIRECTORY}; COMPOSER_MEMORY_LIMIT=-1 COMPOSER_AUTH='${COMPOSER_AUTH}' COMPOSER_ROOT_VERSION=${COMPOSER_ROOT_VERSION} composer require  drush/drush:^9 thunder/thunder_performance_measurement thunder/testsite_builder drupal/media_entity_generic drupal/console --update-no-dev"; \
    \
    echo -e "\nexport PATH=\"\$PATH:${INSTALLATION_DIRECTORY}/bin:${INSTALLATION_DIRECTORY}/vendor/bin\"\n" >> /home/thunder/.profile; \
    \
    su - thunder --command="composer clear-cache";

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

EXPOSE 8080/tcp
CMD ["bash", "-x", "drupal-php-run"]
