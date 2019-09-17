#!/bin/bash
#
# Build Docker image for testing

# Install AWS CLI
pip install --user awscli

# Get latest successful Thunder 8.x-3.x build
THUNDER_LATEST_BUILD_ID=$(curl --request GET 'https://api.travis-ci.com/v3/repo/thunder%2Fthunder-distribution/builds?branch.name=8.x-3.x&build.state=passed&build.event_type=cron,push&limit=1' --header 'Content-Type: application/json' --silent | jq --raw-output '.builds[0].id')

# Thunder project artifact file name
THUNDER_PROJECT_ARTIFACT_FILE="${THUNDER_LATEST_BUILD_ID}-thunder.tar.gz"

# Download project artifact from S3
aws s3 cp "s3://thunder-builds/${THUNDER_PROJECT_ARTIFACT_FILE}" "${TRAVIS_BUILD_DIR}/../"

# Extract files to www directory for Docker image packaging
mkdir -p "${TRAVIS_BUILD_DIR}/www"
tar -zxf "${TRAVIS_BUILD_DIR}/../${THUNDER_PROJECT_ARTIFACT_FILE}" -C "${TRAVIS_BUILD_DIR}/www"

# Build image with tag
./build.sh --tag "travis-ci-test"
