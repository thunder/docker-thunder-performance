#!/bin/bash
#
# Build Docker image for testing

# Get artifact of latest successful Thunder 8.x-5.x build
THUNDER_LATEST_ARTIFACT=$(curl -u "$GITHUB_ACCESS" 'https://api.github.com/repos/thunder/thunder-distribution/actions/workflows/test.yml/runs?event=schedule&conclusion=success' --silent | jq --raw-output '.workflow_runs[0].artifacts_url')

# Get artifact download URL
THUNDER_PROJECT_ARTIFACT_URL=$(curl -u "$GITHUB_ACCESS" "$THUNDER_LATEST_ARTIFACT" --silent | jq --raw-output '.artifacts[0].archive_download_url')

# Download the build zip
curl -u "$GITHUB_ACCESS" "$THUNDER_PROJECT_ARTIFACT_URL" -LO --silent
unzip zip

# Thunder project artifact file name
THUNDER_PROJECT_ARTIFACT_FILE="build.tgz"

# Extract files to www directory for Docker image packaging
mkdir -p "${TRAVIS_BUILD_DIR}"
tar -zxf "${THUNDER_PROJECT_ARTIFACT_FILE}" "thunder"

mv thunder/install "${TRAVIS_BUILD_DIR}/www"

# Build image with tag
bash -x ./build.sh --tag "travis-ci-test"
