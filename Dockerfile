FROM burda/thunder-php:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG NVM_VERSION="v0.34.0"

# Create required user
RUN set -xe; \
    \
    adduser --gecos "" --disabled-password thunder; \
    \
    usermod -aG sudo thunder;

# Install required libraries and packages
RUN set -xe; \
    \
    apt-get update; \
    \
    apt-get install -y --no-install-recommends \
        gnupg \
        apt-transport-https \
    ; \
    \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - ; \
    \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list; \
    \
    apt-get update; \
    \
    apt-get install -y --no-install-recommends \
        yarn \
    ; \
    \
    su - thunder -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh | bash"; \
    \
    echo -e "\nexport NVM_DIR=\"\$HOME/.nvm\"\n[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"\n" >> /home/thunder/.profile; \
    \
    su - thunder -c "nvm install node"; \
    \
    apt list --installed | grep -o '.*-dev' | xargs apt-get purge -y; \
    \
    apt purge -y \
        gnupg \
        apt-transport-https \
    ; \
    \
    apt-get clean; \
    \
    rm -rf /var/lib/apt/lists/*;

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
    su - thunder -c "cd /home/thunder/www/docroot/core; yarn add elastic-apm-node --dev"; \
    \
    su - thunder -c "yarn cache clean"; \
    \
    su - thunder -c "composer global require drush/drush"; \
    \
    echo -e "\nexport PATH=\"\$PATH:/home/thunder/.composer/vendor/bin\"\n" >> /home/thunder/.profile; \
    \
    su - thunder -c "composer clear-cache";

# Define all runtime environments
ENV DB_HOST="127.0.0.1"
ENV DB_NAME="thunder"
ENV DB_USER="thunder"
ENV DB_PASS="thunder"
ENV DB_PORT="3306"
ENV DB_DIVER="mysql"

# Test related environment variables
ENV THUNDER_HOST=localhost
ENV CHROME_HOST=localhost

# Elastic APM integration environments variables
ENV ELASTIC_APM_URL="http://127.0.0.1:8200"
ENV ELASTIC_APM_CONTEXT_TAG_BRANCH="master"

EXPOSE 8080/tcp
CMD ["bash", "-x", "thunder-php-run"]
