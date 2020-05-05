#!/bin/bash
#
# Build Docker image for testing

# Get the latest version of Drupal. Ideally this would be more fixed but it is
# tricky.
git clone --branch "${BRANCH}" --depth=1 https://git.drupalcode.org/project/drupal.git "${TRAVIS_BUILD_DIR}/drupal"

# Build image with tag
sh -x ./build.sh --tag "travis-ci-test" --profile standard --test-group standard --project-path "${TRAVIS_BUILD_DIR}/drupal"
