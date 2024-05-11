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

function 00__is_installed_with_cloudy_core() {
  [ -f "$r/composer.json" ] && [ -f "$r/cloudy/cloudy.sh" ] && return 0
  return 1
}
function is_composer_installed() {
  [ -f "$r/../../../composer.json" ] && return 0
  return 1
}
function 01__is_installed_with_cloudy_pm_install() {
  [ -f "$r/../../cloudy/cloudy/composer.json" ] && [ -f "$r/../../../cloudypm.lock" ] && return 0
  return 1
}
function 04__is_cloudy_framework() {
  [ -f "$r/framework/cloudy/composer.json" ] && [ -f "$r/cloudy_tools.sh" ] && return 0
  return 1
}
function is_cloudy_core_only() {
  [ -f "$r/cloudy/composer.json" ] && return 0
  return 1
}

# If the application script did not explicitly define the path to the composer
# vendor directory, then we will try to find it based on likely scenarios.
# If it's installed as a Composer dependency it will be here:

# THE ORDER HERE IS VERY, VERY_IMPORTANT.  The first match will be used.
00__is_installed_with_cloudy_core && COMPOSER_VENDOR="$r/vendor" && return 0
01__is_installed_with_cloudy_pm_install && COMPOSER_VENDOR="$r/../../cloudy/cloudy/vendor" && return 0
is_composer_installed && COMPOSER_VENDOR="$r/../../../vendor/" && return 0
is_cloudy_core_only && COMPOSER_VENDOR="$r/cloudy/vendor" && return 0
04__is_cloudy_framework && COMPOSER_VENDOR="$r/framework/cloudy/vendor" && return 0
