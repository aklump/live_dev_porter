#!/usr/bin/env bash

#
# Begin Core Controller Section.
#

# Expand some vars from our controlling script.
export CONFIG="$(cd $(dirname "$r/$CONFIG") && pwd)/$(basename $CONFIG)"

if [[ "$LOGFILE" ]]; then
  log_dir="$(dirname $r/$LOGFILE)"
  mkdir -p "$log_dir" || exit_with_failure "Please manually create \"$log_dir\" and ensure it is writeable."
  export LOGFILE="$(cd $log_dir && pwd)/$(basename $LOGFILE)"
fi

_cloudy_define_cloudy_vars

# Store the script options for later use.
parse_args "$@"

declare -a CLOUDY_ARGS=("${parse_args__args[@]}")
declare -a CLOUDY_OPTIONS=("${parse_args__options[@]}")
for option in "${CLOUDY_OPTIONS[@]}"; do
  eval "CLOUDY_OPTION__$(md5_string $option)=\"\$parse_args__options__${option//-/_}\""
done

# Define shared variables
declare -a CLOUDY_FAILURES=()
declare -a CLOUDY_SUCCESSES=()
CLOUDY_EXIT_STATUS=0

#
# Setup caching
#

# For scope reasons we have to source these here and not inside _cloudy_bootstrap.
CACHE_DIR="$CLOUDY_ROOT/cache"
CACHED_CONFIG_FILEPATH="$CACHE_DIR/_cached.$(path_filename $SCRIPT).config.sh"
CACHED_CONFIG_JSON_FILEPATH="$CACHE_DIR/_cached.$(path_filename $SCRIPT).config.json"
CACHED_CONFIG_MTIME_FILEPATH="${CACHED_CONFIG_FILEPATH/.sh/.modified.txt}"
CACHED_CONFIG_HASH_FILEPATH="${CACHED_CONFIG_FILEPATH/.sh/.hash.txt}"

# Ensure the configuration cache environment is present and writeable.
if [ ! -d "$CACHE_DIR" ]; then
  mkdir -p "$CACHE_DIR" || exit_with_failure "Unable to create cache folder: $CACHE_DIR"
fi

#
# PHP Bootstrapping.
#
if [[ "$COMPOSER_VENDOR" ]]; then
  # This will be used when this directory is defined at the top of the entry
  # script as relative to that script.
  COMPOSER_VENDOR="$(cd $(dirname "$r/$COMPOSER_VENDOR") && pwd)/$(basename $COMPOSER_VENDOR)"
fi
# If the application script did not explicitly define the path to the composer
# vendor directory, then we will try to find it based on likely scenarios.
if [[ ! "$COMPOSER_VENDOR" ]]; then
  # If it's installed as a Composer dependency it will be here:
  COMPOSER_VENDOR="$r/../../../vendor/"
  # A stand-alone cloudy script will have it here, e.g. "cloudy new foo.sh".
  [[ ! -d "$COMPOSER_VENDOR" ]] && COMPOSER_VENDOR="$r/cloudy/vendor/"
  # Otherwise a Cloudy app will have it here:
  [[ ! -d "$COMPOSER_VENDOR" ]] && COMPOSER_VENDOR="$r/framework/cloudy/vendor/"
fi
event_dispatch "pre_config" || exit_with_failure "Non-zero returned by on_pre_config()."

[[ -f "$COMPOSER_VENDOR/autoload.php" ]] || exit_with_failure "Composer autoloader not found in $COMPOSER_VENDOR"
export COMPOSER_VENDOR="$(cd $COMPOSER_VENDOR && pwd)"

_cloudy_bootstrap_php || exit_with_failure "Invalid PHP"

compile_config__runtime_files=$(event_dispatch "compile_config")
config_cache_id=$("$CLOUDY_PHP" $CLOUDY_ROOT/php/helpers.php get_config_cache_id "$ROOT\n$compile_config__runtime_files")

# Detect changes in YAML and purge config cache if necessary.
CLOUDY_CONFIG_HAS_CHANGED=false
_cloudy_auto_purge_config

# Generate the cached configuration file.
if [[ ! -f "$CACHED_CONFIG_JSON_FILEPATH" ]]; then
  CLOUDY_CONFIG_HAS_CHANGED=true
  # Normalize the config file to JSON.
  CLOUDY_CONFIG_JSON="$("$CLOUDY_PHP" "$CLOUDY_ROOT/php/config_to_json.php" "$CLOUDY_ROOT/cloudy_config.schema.json" "$CONFIG" "$cloudy_development_skip_config_validation" "$compile_config__runtime_files")"
  json_result=$?
  [[ "$CLOUDY_CONFIG_JSON" ]] || exit_with_failure "\$CLOUDY_CONFIG_JSON cannot be empty in $(basename $BASH_SOURCE) $LINENO"
  [[ $json_result -ne 0 ]] && exit_with_failure "$CLOUDY_CONFIG_JSON"
  echo "$CLOUDY_CONFIG_JSON" >"$CACHED_CONFIG_JSON_FILEPATH"
else
  CLOUDY_CONFIG_JSON="$(cat "$CACHED_CONFIG_JSON_FILEPATH")"
fi

# Generate the cached configuration file.
if [[ ! -f "$CACHED_CONFIG_FILEPATH" ]]; then
  CLOUDY_CONFIG_HAS_CHANGED=true
  touch "$CACHED_CONFIG_FILEPATH" || exit_with_failure "Unable to write cache file: $CACHED_CONFIG_FILEPATH"

  [[ "$cloudy_development_skip_config_validation" == true ]] && write_log_dev_warning "Configuration validation is disabled due to \$cloudy_development_skip_config_validation == true."

  # Convert the JSON to bash config.
  php "$CLOUDY_ROOT/php/json_to_bash.php" "$ROOT" "cloudy_config" "$CLOUDY_CONFIG_JSON" >"$CACHED_CONFIG_FILEPATH"
  if [[ $? -ne 0 ]]; then
    compiled=$(cat "$CACHED_CONFIG_FILEPATH")
    fail_because "$(
      IFS="|"
      read file reason <<<"$compiled"
      echo "$reason"
    )"
    exit_with_failure "Cannot create cached config filepath."
  else
    source "$CACHED_CONFIG_FILEPATH" || exit_with_failure "Cannot load cached configuration."
    eval $(get_config_path -a "additional_config")
    config_files=("$CONFIG" "${additional_config[@]}")
    [[ ${#compile_config__runtime_files[@]} -gt 0 ]] && config_files=("${config_files[@]}" "${compile_config__runtime_files[@]}")
    echo -n >"$CACHED_CONFIG_MTIME_FILEPATH"
    for file in "${config_files[@]}"; do
      if [[ "$file" ]]; then
        if [[ ! -f "$file" ]]; then
          write_log_error "Missing configuration file path: \"$file\"."
        else
          echo "$(realpath "$file") $(_cloudy_get_file_mtime "$file")" >>"$CACHED_CONFIG_MTIME_FILEPATH"
        fi
      fi
    done
    echo $config_cache_id >"$CACHED_CONFIG_HASH_FILEPATH"

    write_log_notice "$(basename $CONFIG) configuration compiled to $CACHED_CONFIG_FILEPATH."
  fi
fi

# Import the cached config variables at this top scope into memory.
source "$CACHED_CONFIG_FILEPATH" || exit_with_failure "Cannot load cached configuration."

#
# End caching setup
#

eval $(get_config config_path_base)
APP_ROOT="$(realpath $ROOT/$config_path_base)"

eval $(get_config -a additional_bootstrap)
if [[ "$additional_bootstrap" != null ]]; then
  for include in "${additional_bootstrap[@]}"; do
    source "$ROOT/$include"
  done
fi

event_dispatch "boot" || exit_with_failure "Could not bootstrap $(get_title)"
_cloudy_bootstrap $@
