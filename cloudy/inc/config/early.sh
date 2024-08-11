#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

# @file
# Read PHP override in *.local.yml and set CLOUDY_PHP
#
# You must source this inside of on_pre_config in your controller.
# @code
# function on_pre_config() {
#  source "$CLOUDY_CORE_DIR/inc/config/early.sh"
# }
# @code
#
# $1 string The relative filepath to the YAML config to search for, e.g.
# ".live_dev_porter/config.local.yml", with content like this:
# @code
# shell_commands:
#   php: /usr/local/bin/php
# @endcode

## Parses YAML and returns the path to a given shell_command.
 #
 # @param string The system command, e.g. "php"
 # @param string The filepath to the YAML file.
 #
 # @echo The configured system path if found.
 #
 ##
function _cloudy_early_config__read_shell_command() {
  local command="$1"
  local path_to_config="$2"

  command_path="$(grep "  $command:" "$path_to_config")"
  # Check if commented out
  command_path="$(_cloudy_ltrim_yaml_array_item "$command_path")"
  [[ "${command_path:0:1}" == '#' ]] && return 0
  # Get the value to the right of the :
  command_path="$(echo "$command_path" | cut -d ':' -f 2 | xargs)"
  echo "$command_path"
}

if [[ ! "$CLOUDY_PHP" ]]; then
  _cloudy_read_unprocessed_additional_config_paths "$CLOUDY_PACKAGE_CONFIG"
  [ $? -ne 0 ] && fail_because "Cannot load or parse $CLOUDY_PACKAGE_CONFIG" && exit_with_failure
  for config_file in "${_cloudy_unprocessed_additional_config_paths__array[@]}"; do
    config_file="$(_cloudy_resolve_path_tokens "$config_file")"
    # TODO Resolve relative config file paths to absolute file? This may be unnecessary if we decide to require absolute paths.
    custom_php=$(_cloudy_early_config__read_shell_command php "$config_file")
    if [[ "$custom_php" ]]; then
      ! [[ -f "$custom_php" ]] && fail_because "invalide shell_command.php path in $config_file" && exit_with_failure
      CLOUDY_PHP="$custom_php"
      php_set_by_config_file="$config_file"
    fi
  done

  if [[ "$CLOUDY_PHP" ]]; then
    write_log_info "\$CLOUDY_PHP set by: $php_set_by_config_file"
  fi
fi

# Find the config YAML file that might contain the PHP override.
#
# Returns 0 if .
#function _cloudy_early_config__find_config() {
#  local relative_path="$1"
#  test / == "$PWD" && return 1
#  test -e "./$relative_path" && echo "${PWD}/$relative_path" && return 0
#  cd .. && _cloudy_early_config__find_config "$relative_path"
#}

#  # Search for an additional_config with the ".local.yml" suffix; this is where
#  # the php override must be located for this to work.
#  relative_path=$(_cloudy_early_config__get_relative_path "$CLOUDY_PACKAGE_CONFIG")
#
#
##  [[ ! "$relative_path" ]] && return 0
#debug "$relative_path;\$relative_path"
#  absolute_path=$(cd "$ROOT" && _cloudy_early_config__find_config "$relative_path")
##  [[ ! "$absolute_path" ]] && return 0
#debug "$absolute_path;\$absolute_path"
#
