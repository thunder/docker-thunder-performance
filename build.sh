#!/bin/bash
#
# Build thunder performance docker image

if [ "$1" == "" ]; then
    echo "usage: build.sh <path to Thunder project>"

    exit 1
fi

# Check if correct directory path is provided
if [ ! -d "$1" ]; then
    echo "Provided directory path is not correct."

    exit 1
fi

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Copy Thunder prject to Dockerfile context
cp -LR $1 "${SCRIPT_DIRECTORY}/www"

# CleanUp project
find "${SCRIPT_DIRECTORY}/www" -type d -name ".git" | xargs rm -rf

# Build docker image
docker build "${SCRIPT_DIRECTORY}"
