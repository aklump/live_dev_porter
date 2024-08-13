#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

source "$CLOUDY_CORE_DIR/inc/cloudy.define_variables.sh"

##
 # @file Processes variables during the bootstrapping.
 #
 # @export string $CLOUDY_PACKAGE_CONFIG
 # @export string $CLOUDY_RUNTIME_UUID
 # @global string $CLOUDY_BASEPATH
 # @global string $CLOUDY_INSTALLED_AS
 # @global string $CLOUDY_LOG
 # @global string $CLOUDY_TMPDIR
 # @global string $CLOUDY_PACKAGE_ID
 ##

if [[ ! "$CLOUDY_PACKAGE_ID" ]]; then
  CLOUDY_PACKAGE_ID="$(path_filename "$CLOUDY_PACKAGE_CONTROLLER")"
fi
declare -xr CLOUDY_PACKAGE_ID="$CLOUDY_PACKAGE_ID"
write_log_debug "\$CLOUDY_PACKAGE_ID is \"$CLOUDY_PACKAGE_ID\""

declare -xr CLOUDY_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/$CLOUDY_PACKAGE_ID.XXXXXXXXXX")"
write_log_debug "\$CLOUDY_TMPDIR is \"$CLOUDY_TMPDIR\""

# I don't think this needs to be developer-configurable.
declare -xr CLOUDY_INIT_RULES="$(path_make_absolute 'init_resources/cloudy_init_rules.yml' "$ROOT")"
write_log_debug "\$CLOUDY_INIT_RULES is \"$CLOUDY_INIT_RULES\""

# Expand some vars from our controlling script.
if [[ "$CLOUDY_PACKAGE_CONFIG" ]] && ! path_is_absolute "$CLOUDY_PACKAGE_CONFIG"; then
  CLOUDY_PACKAGE_CONFIG="$(cd $(dirname "$r/$CLOUDY_PACKAGE_CONFIG") && pwd)/$(basename $CLOUDY_PACKAGE_CONFIG)"
fi
if [[ "$CLOUDY_PACKAGE_CONFIG" ]] && [ -f "$CLOUDY_PACKAGE_CONFIG" ]; then
  CLOUDY_PACKAGE_CONFIG="$(path_make_canonical "$CLOUDY_PACKAGE_CONFIG")"
fi
declare -rx CLOUDY_PACKAGE_CONFIG="$CLOUDY_PACKAGE_CONFIG"
write_log_debug "\$CLOUDY_PACKAGE_CONFIG is \"$CLOUDY_PACKAGE_CONFIG\""

# The log will be enabled one of two ways, either by the use in the shell that
# initiates the controller, in which case relative paths should be made absolute
# by $PWD.  Otherwise if $controller_log is set, the assumption is that was set
# in the package controller, and relative paths should be made absolute to the
# controller directory.
if [[ "$CLOUDY_LOG" ]]; then
  p="$(path_make_absolute "$CLOUDY_LOG" "$PWD")" && CLOUDY_LOG="$p"
elif [[ "$controller_log" ]]; then
  p="$(path_make_absolute "$controller_log" "$r")" && controller_log="$p"
  CLOUDY_LOG="$controller_log"
fi
unset controller_log

# Ensure the log file parent directories exist so the log can be written.
if [[ "$CLOUDY_LOG" ]]; then
  log_dir="$(dirname "$CLOUDY_LOG")"
  if ! mkdir -p "$log_dir"; then
    fail_because "Please manually create \"$log_dir\" and ensure it is writeable."
    return 2
  fi
  declare -rx CLOUDY_LOG="$(cd "$log_dir" && pwd)/$(basename $CLOUDY_LOG)"
fi

declare -rx CLOUDY_PACKAGE_CONTROLLER="$(path_make_canonical "$CLOUDY_PACKAGE_CONTROLLER")"
write_log_debug "\$CLOUDY_PACKAGE_CONTROLLER is \"$CLOUDY_PACKAGE_CONTROLLER\""

# Detect installation type
declare -rx CLOUDY_INSTALLED_AS=$(_cloudy_detect_installation_type "$CLOUDY_PACKAGE_CONTROLLER")
write_log_debug "\$CLOUDY_INSTALLED_AS autodetected as \"$CLOUDY_INSTALLED_AS\""

declare -rx CLOUDY_RUNTIME_UUID=$(create_uuid)

# Holds the path of the controlling script that is executing $PHP_FILE_RUNNER;
# can be read by the PHP file to know it's parent script.
declare -x PHP_FILE_RUN_CONTROLLER=''
