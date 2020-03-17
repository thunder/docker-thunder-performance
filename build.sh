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
                echo "Provided directory path is not correct."

                exit 1
            fi

            PROJECT_PATH="$2"

            shift
            ;;

        *) echo "Option $1 not recognized." ;;
    esac

    shift
done

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Copy Thunder prject to Dockerfile context if project path is provided
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
docker build "${SCRIPT_DIRECTORY}" --tag "${TAG_NAME}"
