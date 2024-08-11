#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # Begin Core Controller Section.
 #
 # @global array $CLOUDY_ARGS
 # @global array $CLOUDY_FAILURES
 # @global array $CLOUDY_INSTALLED_AS
 # @global array $CLOUDY_OPTIONS
 # @global array $CLOUDY_SUCCESSES
 # @global int $CLOUDY_EXIT_STATUS
 # @global string $CLOUDY_OPTIONS__*
 # @global string $CLOUDY_PACKAGE_CONFIG
 #
 # @export string $CLOUDY_BASEPATH
 # @export string $CLOUDY_CACHE_DIR
 # @export string $CLOUDY_PHP
 # @export string $CLOUDY_COMPOSER_VENDOR
 # @export string $CLOUDY_LOG
 ##
source "$CLOUDY_CORE_DIR/inc/bootstrap/variables.sh"
source "$CLOUDY_CORE_DIR/inc/bootstrap/basepath.sh"
source "$CLOUDY_CORE_DIR/inc/review_code/cloudy_package_controller.sh"
has_failed && exit_with_failure

# Store the script options for later use.
parse_args "$@"
declare -a CLOUDY_ARGS=("${parse_args__args[@]}")
declare -a CLOUDY_OPTIONS=("${parse_args__options[@]}")
for option in "${CLOUDY_OPTIONS[@]}"; do
  eval "CLOUDY_OPTION__$(md5_string $option)=\"\$parse_args__options__${option//-/_}\""
done

source "$CLOUDY_CORE_DIR/inc/bootstrap/caching.sh"
source "$CLOUDY_CORE_DIR/inc/bootstrap/php.sh"
has_failed && exit_with_failure "Failed to bootstrap Cloudy PHP in bootstrap/php.sh."
source "$CLOUDY_CORE_DIR/inc/bootstrap/config.sh"
has_failed && exit_with_failure "Failed to bootstrap Cloudy core."

event_dispatch "boot" || exit_with_failure "Failed to boot $(get_title)"
_cloudy_bootstrap $@
