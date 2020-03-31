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
        --drupal-version)
            COMPOSER_ROOT_VERSION="$2"

            shift
            ;;


        *) echo "Option $1 not recognized." ;;
    esac

    shift
done

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Copy Thunder project to Dockerfile context if project path is provided
if [[ "${PROJECT_PATH}" != "" ]]; then
    if [[ "${OS_NAME}" == "osx" ]]; then
        rm -rf "${SCRIPT_DIRECTORY}/www"
        cp -R "${PROJECT_PATH}" "${SCRIPT_DIRECTORY}/www"
    else
        rm --recursive --force  "${SCRIPT_DIRECTORY}/www"
        cp --dereference --recursive "${PROJECT_PATH}" "${SCRIPT_DIRECTORY}/www"
    fi
fi

# CleanUp project
if [[ "${OS_NAME}" == "osx" ]]; then
  find "${SCRIPT_DIRECTORY}/www" -type d -name ".git" -print0 | xargs -0 rm -rf
else
  find "${SCRIPT_DIRECTORY}/www" -type d -name ".git" -print0 | xargs -0 rm --recursive --force
fi

# Build docker image
docker build --build-arg COMPOSER_AUTH="${COMPOSER_AUTH}" --build-arg PROFILE="${PROFILE}" --build-arg COMPOSER_ROOT_VERSION="${COMPOSER_ROOT_VERSION}" --build-arg THUNDER_TEST_GROUP="${THUNDER_TEST_GROUP}" "${SCRIPT_DIRECTORY}" --tag "${TAG_NAME}"
