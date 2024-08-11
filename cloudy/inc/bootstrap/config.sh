#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # @file Bootstrap the configuration layer.
 ##

declare -rx CLOUDY_RUNTIME_ENV="$CLOUDY_CACHE_DIR/_runtime_vars.$CLOUDY_RUNTIME_UUID.sh";

compile_config__runtime_files=$(event_dispatch "compile_config")

config_cache_id=$(. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/functions/invoke.php" "_cloudy_get_config_cache_id" "$ROOT\n$compile_config__runtime_files")

source "$CLOUDY_CORE_DIR/inc/config/normalize.sh" || exit_with_failure "Cannot normalize configuration."
source "$CLOUDY_CORE_DIR/inc/config/cache.sh" || exit_with_failure "Cannot cache configuration."

# Now load the normalized, cached config into memory.
source "$CACHED_CONFIG_FILEPATH" || exit_with_failure "Cannot load cached configuration."
eval $(get_config_path_as -a '_additional_bootstraps' 'additional_bootstrap')

if [ ${#_additional_bootstraps[@]} -gt 0 ]; then
  for _additional_bootstrap_file in "${_additional_bootstraps[@]}"; do
    ! [ -f "$_additional_bootstrap_file" ] && fail_because "Invalid additional_bootstrap: $_additional_bootstrap_file" && exit_with_failure
    source "$_additional_bootstrap_file"
  done
  unset _additional_bootstrap
  unset _additional_bootstrap_file
fi

