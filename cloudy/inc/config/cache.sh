#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # @global string $CACHED_CONFIG_FILEPATH
 # @global string $CACHED_CONFIG_HASH_FILEPATH
 # @global string $CACHED_CONFIG_MTIME_FILEPATH
 # @global string $CLOUDY_CONFIG_HAS_CHANGED
 # @global string $CLOUDY_CONFIG_JSON
 # @global string $CLOUDY_PACKAGE_CONFIG
 # @global string $CLOUDY_CORE_DIR
 # @global string $ROOT

[[ -f "$CACHED_CONFIG_FILEPATH" ]] && return 0

# Generate the cached configuration file from JSON config.
CLOUDY_CONFIG_HAS_CHANGED=true
! touch "$CACHED_CONFIG_FILEPATH" && fail_because "Unable to write cache file: $CACHED_CONFIG_FILEPATH" && return 2

[[ "$cloudy_development_skip_config_validation" == true ]] && write_log_dev_warning "Configuration validation is disabled due to \$cloudy_development_skip_config_validation == true."

# Convert the JSON to bash config.
. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/config/cache.php" "$ROOT" "cloudy_config" "$CLOUDY_CONFIG_JSON" >"$CACHED_CONFIG_FILEPATH"
json_to_bash_result=$?
if [[ $json_to_bash_result -ne 0 ]]; then
  fail_because "php/config/cache.php exited with code $json_result".
  fail_because "$(cat "$CACHED_CONFIG_FILEPATH"|tr -d '\n')"
  rm "$CACHED_CONFIG_FILEPATH"
  fail_because "Check log for more information."
  fail_because "Cannot cache config to: $CACHED_CONFIG_FILEPATH."
  return 3
else
  ! source "$CACHED_CONFIG_FILEPATH" && fail_because "Cannot load cached configuration." && return 4
  eval $(get_config_path_as -a "additional_config" "additional_config")
  config_files=("$CLOUDY_PACKAGE_CONFIG" "${additional_config[@]}")
  [[ ${#compile_config__runtime_files[@]} -gt 0 ]] && config_files=("${config_files[@]}" "${compile_config__runtime_files[@]}")
  echo -n >"$CACHED_CONFIG_MTIME_FILEPATH"
  for file in "${config_files[@]}"; do
    if [[ "$file" ]]; then
      if [[ ! -f "$file" ]]; then
        fail_because "Missing configuration file path: \"$file\"."
        write_log_error "Missing configuration file path: \"$file\"."
      else
        echo "$(realpath "$file") $(_cloudy_get_file_mtime "$file")" >>"$CACHED_CONFIG_MTIME_FILEPATH"
      fi
    fi
  done
  echo $config_cache_id >"$CACHED_CONFIG_HASH_FILEPATH"

  write_log_notice "$(basename $CLOUDY_PACKAGE_CONFIG) configuration compiled to $CACHED_CONFIG_FILEPATH."
fi

has_failed && return 1
return 0
