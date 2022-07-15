#!/usr/bin/env bash

# @file
#
# Bootstrap the plugin configuration
#

# Create a unique list of active plugins.
declare -a ACTIVE_PLUGINS=('default')

# This will load the database plugins for all environments.
for environment_id in "${ENVIRONMENT_IDS[@]}"; do
  eval $(get_config_keys_as database_ids "environments.$environment_id.databases")
  for database_id in "${database_ids[@]}"; do
    eval $(get_config_as plugin "environments.$environment_id.databases.$database_id.plugin")
    ACTIVE_PLUGINS=("${ACTIVE_PLUGINS[@]}" "$plugin")
  done
done

ACTIVE_PLUGINS=($(echo "$(printf "%s\n" "${ACTIVE_PLUGINS[@]}")" | sort -u))
