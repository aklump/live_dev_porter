#!/usr/bin/env bash

#
# @file
# Locate the composer vendor directory.

if [[ "$COMPOSER_VENDOR" ]]; then
  # This will be used when this directory is defined at the top of the entry
  # script as relative to that script.  We look to see if it needs to be
  # resolved to an absolute path and then exit.
  if ! path_is_absolute "$COMPOSER_VENDOR"; then
    COMPOSER_VENDOR="$(cd $(dirname "$r/$COMPOSER_VENDOR") && pwd)/$(basename $COMPOSER_VENDOR)"
  fi
  return 0
fi


function is_composer_installed() {
  [ -f "$r/../../../composer.json" ] && return 0
  return 1
}
function is_cloudy_pm_installed() {
  [ -f "$r/../../cloudy/cloudy/composer.json" ] && return 0
  return 1
}
function is_cloudy_app_installed() {
  [ -f "$r/framework/cloudy/composer.json" ] && return 0
  return 1
}
function is_standalone_installed() {
  [ -f "$r/cloudy/composer.json" ] && return 0
  return 1
}
function is_composer_create_project_installed() {
  [ -f "$r/composer.json" ] && [ -d "$r/cloudy" ] && return 0
  return 1
}

# If the application script did not explicitly define the path to the composer
# vendor directory, then we will try to find it based on likely scenarios.
# If it's installed as a Composer dependency it will be here:

is_cloudy_pm_installed && COMPOSER_VENDOR="$r/../../cloudy/cloudy/vendor" && return 0
is_cloudy_app_installed && COMPOSER_VENDOR="$r/framework/cloudy/vendor" && return 0
is_standalone_installed && COMPOSER_VENDOR="$r/cloudy/vendor" && return 0
is_composer_installed && COMPOSER_VENDOR="$r/../../../vendor/" && return 0
is_composer_create_project_installed && COMPOSER_VENDOR="$r/vendor" && return 0
