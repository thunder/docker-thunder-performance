#!/bin/bash
#
# Build Docker image for testing

# Docker ID of Thunder PHP container
TEST_THUNDER_PHP_DOCKER_ID="test_thunder-php_1"

# Maximum wait time in seconds (15 mins)
MAX_WAIT=900

# Prepare max wait time
CURRENT_TIMESTAMP=$(date +%s)
WAIT_UNTIL_TIMESTAMP=$((CURRENT_TIMESTAMP + MAX_WAIT))

# Wait for server to be ready
until $(curl --output /dev/null --silent --head --fail "http://localhost:8080/"); do
    if [ $(date +%s) -gt ${WAIT_UNTIL_TIMESTAMP} ]; then
      echo "Max execution time exceeded"

      exit 1
    fi

    printf '.'
    sleep 10
done

# Check that Thunder is running correctly
curl -s "http://localhost:8080/" | grep -q "meta.*Generator.*Thunder"

# Check that relevant modules are installed
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder -c 'cd www; drush pml --status=enabled --format=json;' | jq -e '.thunder_performance_measurement'

# Check that required Node.JS package is installed for Elastic APM
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder -c 'cd /home/thunder/www/docroot/core/node_modules/elastic-apm-node;'

# Check that envirovment variables are set for thunder user
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder -c '[ "${THUNDER_HOST}" == "localhost" ] && [ ${CHROME_HOST} == "chrome" ] && echo "All Good!" || exit 1'
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder -c '[ ${ELASTIC_APM_URL} == "http://127.0.0.1:8200" ] && [ ${ELASTIC_APM_CONTEXT_TAG_BRANCH} == "travis-ci-test" ] && echo "All Good!" || exit 1'
