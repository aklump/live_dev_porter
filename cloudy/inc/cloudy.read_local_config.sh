#!/usr/bin/env bash

# @file
# Read PHP override in *.local.yml and set CLOUDY_PHP
#
# You should source this inside of on_pre_config in your controller.
# @code
# function on_pre_config() {
#  source "$CLOUDY_ROOT/inc/cloudy.read_local_config.sh"
# }
# @code
#
# $1 string The relative filepath to the YAML config to search for, e.g.
# ".live_dev_porter/config.local.yml", with content like this:
# @code
# shell_commands:
#   php: /usr/local/bin/php
# @endcode

# Echo the relative path to *.local.yml
#
# Returns 0 if .
function _read_local_config_get_relative_path() {
  local filename=$1
  local array=()
  local parse=false
  while IFS= read -r line
  do
    if [[ $line == "additional_config:"* ]]; then
      parse=true
      continue
    elif [[ $line == *":" && $line != "additional_config:"* ]]; then
      parse=false
    fi
    if [[ $parse = true && $line == *'-'* ]]; then
      item=${line//- /}
      if [[ $item == *"config.local.yml"* ]]; then
        array+=("$item")
      fi
    fi
  done < "$filename"
  [[ ! "${array[@]}" ]] && return 1
  config="${array[@]#"${array[@]%%[![:space:]]*}"}"
  echo "$config"
}

# Find the config YAML file that might contain the PHP override.
#
# Returns 0 if .
function _read_local_config_find_config() {
  local relative_path="$1"
  test / == "$PWD" && return 1
  test -e "./$relative_path" && echo "${PWD}/$relative_path" && return 0
  cd .. && _read_local_config_find_config "$relative_path"
}

# Parses YAML and returns the PHP override if present.
#
# $1 - The filepath to the YAML file.
#
# Returns 0 if .
function _read_local_config_read_shell_commands_php() {
  local path_to_config="$1"
  custom_php="$(grep '  php:' "$path_to_config")"
  custom_php="${custom_php#"${custom_php%%[![:space:]]*}"}"
  [[ "${custom_php:0:1}" == '#' ]] && custom_php=''
  custom_php="$(echo "$custom_php" | cut -d ':' -f 2 | xargs)"
  echo "$custom_php"
}

if [[ ! "$CLOUDY_PHP" ]]; then

  # Search for an additional_config with the ".local.yml" suffix; this is where
  # the php override must be located for this to work.
  relative_path=$(_read_local_config_get_relative_path "$CONFIG")
  [[ ! "$relative_path" ]] && return 0

  absolute_path=$(cd "$ROOT" && _read_local_config_find_config "$relative_path")
  [[ ! "$absolute_path" ]] && return 0

  CLOUDY_PHP=$(_read_local_config_read_shell_commands_php "$absolute_path")
  [[ ! "$CLOUDY_PHP" ]] && return 0

  write_log_info "\$CLOUDY_PHP set to: $CLOUDY_PHP"
  write_log_info "\$CLOUDY_PHP set by: $absolute_path"
fi

