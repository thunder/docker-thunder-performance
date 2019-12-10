# hadolint ignore=DL3007
FROM burda/thunder-php:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG NVM_VERSION="v0.34.0"

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
    apt-get install --yes --no-install-recommends gnupg apt-transport-https; \
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
COPY scripts/docker/thunder-php-install /usr/local/bin/
COPY scripts/docker/thunder-php-test /usr/local/bin/
COPY scripts/docker/thunder-php-run /usr/local/bin/

# Set executable
RUN set -xe; \
    \
    chmod +x /usr/local/bin/thunder-php-install; \
    \
    chmod +x /usr/local/bin/thunder-php-test; \
    \
    chmod +x /usr/local/bin/thunder-php-run;

# Copy pre-build Thunder project to container
COPY --chown=thunder:thunder www /home/thunder/www

# Install Elastic APM
RUN set -xe; \
    \
    su - thunder --command="cd /home/thunder/www/docroot/core; yarn add elastic-apm-node --dev"; \
    \
    su - thunder --command="yarn cache clean"; \
    \
    su - thunder --command="composer global require drush/drush"; \
    \
    echo -e "\nexport PATH=\"\$PATH:/home/thunder/.composer/vendor/bin\"\n" >> /home/thunder/.profile; \
    \
    su - thunder --command="composer clear-cache";

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
ENV THUNDER_TEST_GROUP="Thunder_Base_Set"

# Elastic APM integration environments variables
ENV ELASTIC_APM_URL="http://127.0.0.1:8200"
ENV ELASTIC_APM_CONTEXT_TAG_BRANCH="master"

EXPOSE 8080/tcp
CMD ["bash", "-x", "thunder-php-run"]
