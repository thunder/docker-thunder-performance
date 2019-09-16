#!/bin/bash
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
    cp --dereference --recursive "${PROJECT_PATH}" "${SCRIPT_DIRECTORY}/www"
fi

# CleanUp project
find "${SCRIPT_DIRECTORY}/www" -type d -name ".git" | xargs rm --recursive --force

# Build docker image
docker build "${SCRIPT_DIRECTORY}" --tag "${TAG_NAME}"
