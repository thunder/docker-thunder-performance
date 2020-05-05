#!/bin/bash
#
# Build Docker image for testing

# Get the latest version of Drupal. Ideally this would be more fixed but it is
# tricky.
git clone --branch "${BRANCH}" --depth=1 https://git.drupalcode.org/project/drupal.git "/tmp/drupal"

# Build image with tag
bash -x ./build.sh --tag "travis-ci-test" --profile "${PROFILE}" --test-group "${PROFILE}" --project-path "/tmp/drupal"
