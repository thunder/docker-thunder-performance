#!/bin/bash
set -e

case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    export OS_NAME=linux
    ;;
  darwin*)
    export OS_NAME=osx
    ;;
  msys*)
    export OS_NAME=windows
    ;;
  *)
    export OS_NAME=notset
    ;;
esac

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
  if [ "${OS_NAME}" == "osx" ]; then
      rm -rf "${SCRIPT_DIRECTORY}/www"
      cp -R "${PROJECT_PATH}" "${SCRIPT_DIRECTORY}/www"
  else
      rm --recursive --force  "${SCRIPT_DIRECTORY}/www"
      cp --dereference --recursive "${PROJECT_PATH}" "${SCRIPT_DIRECTORY}/www"
  fi
fi

# Compose project to ensure dependencies are correct.
cd "${SCRIPT_DIRECTORY}/www"
composer install
composer require drush/drush thunder/thunder_performance_measurement thunder/testsite_builder drupal/media_entity_generic drupal/console
cd "${SCRIPT_DIRECTORY}"

# CleanUp project
# Coder has uncommitted changes due to Drupal's cleaner removing tests.
if [ "${OS_NAME}" == "osx" ]; then
  rm -rf "${SCRIPT_DIRECTORY}/www/vendor/drupal/coder"
else
  rm --recursive --force "${SCRIPT_DIRECTORY}/www/vendor/drupal/coder"
fi

# Note: do not use -d on composer as it can end up reverting changes.
cd "${SCRIPT_DIRECTORY}/www"
composer install --no-dev
cd "${SCRIPT_DIRECTORY}"

# Remove all git info for smaller docker images.
if [ "${OS_NAME}" == "osx" ]; then
  find "${SCRIPT_DIRECTORY}/www" -type d -name ".git" -print0 | xargs -0 rm -rf
else
  find "${SCRIPT_DIRECTORY}/www" -type d -name ".git" -print0 | xargs -0 rm --recursive --force
fi

# Build docker image
docker build --build-arg PROFILE="${PROFILE}" --build-arg THUNDER_TEST_GROUP="${THUNDER_TEST_GROUP}" "${SCRIPT_DIRECTORY}" --tag "${TAG_NAME}"
