#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # @file Normalize, aggregate and cache all config files to CLOUDY_CONFIG_JSON
 #
 # @export string $CLOUDY_CONFIG_JSON
 # @global string $BASH_SOURCE
 # @global string $CACHED_CONFIG_JSON_FILEPATH
 # @global string $CLOUDY_CONFIG_HAS_CHANGED
 # @global string $CLOUDY_CORE_DIR
 # @global string $CLOUDY_PACKAGE_CONFIG
 # @global string $LINENO
 ##

CLOUDY_CONFIG_HAS_CHANGED=false
! _cloudy_auto_purge_config && fail_because "Cannot auto purge config." && return 2

if [ -f "$CACHED_CONFIG_JSON_FILEPATH" ]; then
  export CLOUDY_CONFIG_JSON="$(cat "$CACHED_CONFIG_JSON_FILEPATH")"
  return 0
fi

CLOUDY_CONFIG_HAS_CHANGED=true
write_log_debug "$(basename $CACHED_CONFIG_JSON_FILEPATH) will be (re)built."

# Normalize the config file to JSON.
export CLOUDY_CONFIG_JSON="$(. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/config/normalize.php" "$CLOUDY_CORE_DIR/cloudy_config.schema.json" "$CLOUDY_PACKAGE_CONFIG" "$cloudy_development_skip_config_validation" "$compile_config__runtime_files")"
json_result=$?

if [[ ! "$CLOUDY_CONFIG_JSON" ]]; then
  fail_because "normalize.php returned empty JSON; exit code $json_result".
  fail_because "\$CLOUDY_CONFIG_JSON cannot be empty in $(basename $BASH_SOURCE) $LINENO"
  return 3
fi

[[ $json_result -ne 0 ]] && fail_because "$CLOUDY_CONFIG_JSON" && return 4

# Write the normalized config as a JSON file.
echo "$CLOUDY_CONFIG_JSON" >"$CACHED_CONFIG_JSON_FILEPATH" && return 0

# Unknown error.
return 1
