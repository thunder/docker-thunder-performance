#!/bin/bash
set -e

#
# Build thunder performance docker image

TAG_NAME=""
PROJECT_PATH=""
PROFILE="thunder"
THUNDER_TEST_GROUP="Thunder_Base_Set"

# Process script options
while [ -n "$1" ]; do
    case "$1" in
        --tag)
            TAG_NAME="$2"

            shift
            ;;
        --project-path)
            # Check if correct directory path is provided
            if [ ! -d "$2" ]; then
                echo "Provided project path is not a directory."

                exit 1
            fi

            PROJECT_PATH="$2"

            shift
            ;;

        --profile)
            PROFILE="$2"

            shift
            ;;

        --test-group)
            THUNDER_TEST_GROUP="$2"

            shift
            ;;

        *) echo "Option $1 not recognized." ;;
    esac

    shift
done

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Copy Thunder project to Dockerfile context if project path is provided
if [ "${PROJECT_PATH}" != "" ]; then
  ADDITIONAL_DEPS=("drush/drush" "thunder/thunder_performance_measurement" "thunder/testsite_builder")
  # if [ "${PROFILE}" == "thunder" ]; then
  #   @todo move from thunder_demo to thunder_testing_demo - in order to do this
  #   we'll need to fix the fact that under test composer install --no-dev
  #   removes this when the project path is not passed in. This is how
  #   test/travis-ci-build-thunder.sh works.
  #   ADDITIONAL_DEPS+=("thunder/thunder_testing_demo")
  # fi

  rm -rf "${SCRIPT_DIRECTORY}/www"
  cp -R "${PROJECT_PATH}" "${SCRIPT_DIRECTORY}/www"
  # Compose project to ensure dependencies are correct.
  cd "${SCRIPT_DIRECTORY}/www"
  COMPOSER_MEMORY_LIMIT=-1 composer require "${ADDITIONAL_DEPS[@]}"
  cd "${SCRIPT_DIRECTORY}"
#else
  # @todo Ensure a the minimum of build tools.
  # cd "${SCRIPT_DIRECTORY}/www"
  # composer require drush/drush drupal/console
  # cd "${SCRIPT_DIRECTORY}"
fi

# CleanUp project
# Coder has uncommitted changes due to Drupal's cleaner removing tests.
rm -rf "${SCRIPT_DIRECTORY}/www/vendor/drupal/coder"

# Note: do not use -d on composer as it can end up reverting changes.
#cd "${SCRIPT_DIRECTORY}/www"
#composer install --no-dev
#cd "${SCRIPT_DIRECTORY}"

# Remove all git info for smaller docker images.
find "${SCRIPT_DIRECTORY}/www" -type d -name ".git" -print0 | xargs -0 rm -rf

# Build docker image
docker build --build-arg PROFILE="${PROFILE}" --build-arg THUNDER_TEST_GROUP="${THUNDER_TEST_GROUP}" "${SCRIPT_DIRECTORY}" --tag "${TAG_NAME}"
