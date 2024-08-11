#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # Checks for outdated and legacy code, suggests upgrade steps, exits with failure.
 #
 # @global string $CLOUDY_PACKAGE_CONTROLLER
 ##

if [[ "$LOGFILE" ]]; then
  fail_because 'LOGFILE was changed in Cloudy 2.0; replace with CLOUDY_LOG'
fi
if [[ "$CONFIG" ]]; then
  fail_because 'CONFIG was changed in Cloudy 2.0; replace with CLOUDY_PACKAGE_CONFIG'
fi
if [[ "$APP_ROOT" ]]; then
  fail_because 'APP_ROOT was changed in Cloudy 2.0; replace with CLOUDY_BASEPATH'
fi

has_failed && fail_because "Problem in $CLOUDY_PACKAGE_CONTROLLER" && return 1
return 0
