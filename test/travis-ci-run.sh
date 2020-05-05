#!/usr/bin/env bash
#
# Build Docker image for testing

# Maximum wait time in seconds (15 mins)
MAX_WAIT=900

# Prepare max wait time
CURRENT_TIMESTAMP=$(date +%s)
WAIT_UNTIL_TIMESTAMP=$((CURRENT_TIMESTAMP + MAX_WAIT))

# Wait for server to be ready
until curl --output /dev/null --silent --head --fail "http://localhost:8080/"; do
    if [[ $(date +%s) -gt "${WAIT_UNTIL_TIMESTAMP}" ]]; then
      echo "Max execution time exceeded"

      exit 1
    fi

    printf '.'
    sleep 10
done

# Check that Thunder is running correctly
curl --silent "http://localhost:8080/" | grep --ignore-case --silent "meta.*generator.*${INSTALL}"

# Docker ID of Thunder PHP container
TEST_THUNDER_PHP_DOCKER_ID=$(docker ps --format 'table {{.Names}}' | grep 'thunder-php')

if [ "${PROFILE}" == "thunder" ]; then
  # Check that relevant modules are installed
  docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='cd {$DOC_ROOT}; drush pm:list --status=enabled --format=json;' | jq --exit-status '.thunder_performance_measurement, .media_entity_generic'

  # Workaround for testsite_builder module name until Drush is fixed
  # TODO: Move check back to "drush pm:list" command when Drush issue is fixed (https://github.com/drush-ops/drush/issues/4182)
  docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='cd {$DOC_ROOT}; /home/thunder/www/vendor/drupal/console/bin/drupal debug:module --status=enabled;' | grep --silent "testsite_builder"

  # Check that test site template is fetched
  docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='ls {$DOC_ROOT}/thunder_test_site_template.json;'
fi

# Check that required Node.JS package is installed for Elastic APM
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='cd {$DOC_ROOT}/core/node_modules/elastic-apm-node;'

# Check that envirovment variables are set for thunder user
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='[ "${THUNDER_HOST}" == "thunder-php" ] && [ "${CHROME_HOST}" == "chrome" ] && echo "All Good!" || exit 1'
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='[ "${ELASTIC_APM_URL}" == "http://127.0.0.1:8200" ] && [ "${ELASTIC_APM_CONTEXT_TAG_BRANCH}" == "travis-ci-test" ] && echo "All Good!" || exit 1'
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='[ "${THUNDER_TEST_SITE_TEMPLATE}" == "https://raw.githubusercontent.com/thunder/thunder-performance-site-templates/master/thunder_base_set.json" ] && echo "All Good!" || exit 1'
docker exec "${TEST_THUNDER_PHP_DOCKER_ID}" su - thunder --command='[ "${THUNDER_TEST_GROUP}" == "Thunder_Base_Set" ] && echo "All Good!" || exit 1'
