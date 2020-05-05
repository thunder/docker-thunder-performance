#!/bin/bash
#
# Build Docker image for testing

# Get the latest version of Drupal. Ideally this would be more fixed but it is
# tricky.
git clone --depth=1 git@git.drupal.org:project/drupal.git drupal

# Build image with tag
sh -x ./build.sh --tag "travis-ci-test" --profile standard --test-group standard --project-path ./drupal
