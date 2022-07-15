#!/usr/bin/env bash

# @file
#
# Bootstrap the plugin configuration
#

# Allow the configuration to use tokens which this expands.
#
# $1 - Value that may contain a token.
function _token_expand() {
  local value="$1"
  value=${value//LOCAL_PLUGIN/$LOCAL_PLUGIN}
  value=${value//REMOTE_PLUGIN/$REMOTE_PLUGIN}
  echo "$value"
}

eval $(get_config_as LOCAL_PLUGIN "environments.$LOCAL_ENV_ID.plugin")
[[ "$LOCAL_PLUGIN" ]] || LOCAL_PLUGIN="default"
eval $(get_config_as REMOTE_PLUGIN "environments.$REMOTE_ENV_ID.plugin")
[[ "$REMOTE_PLUGIN" ]] || REMOTE_PLUGIN="default"


eval $(get_config_as PLUGIN_LOCAL_DB_SHELL 'plugin_assignments.shell.db')
PLUGIN_LOCAL_DB_SHELL=$(_token_expand $PLUGIN_LOCAL_DB_SHELL)

eval $(get_config_as PLUGIN_REMOTE_SSH_SHELL 'plugin_assignments.shell.remote')
PLUGIN_REMOTE_SSH_SHELL=$(_token_expand $PLUGIN_REMOTE_SSH_SHELL)

# Create a unique list of active plugins.
declare -a ACTIVE_PLUGINS=($PLUGIN_EXPORT_LOCAL_DB $PLUGIN_LOCAL_DB_SHELL $PLUGIN_REMOTE_SSH_SHELL)

# This will load the database plugins for all environments.
for environment_id in "${ENVIRONMENT_IDS[@]}"; do
  eval $(get_config_keys_as database_ids "environments.$environment_id.databases")
  for database_id in "${database_ids[@]}"; do
    eval $(get_config_as plugin "environments.$environment_id.databases.$database_id.plugin")
    ACTIVE_PLUGINS=("${ACTIVE_PLUGINS[@]}" "$plugin")
  done
done

ACTIVE_PLUGINS=($(echo "$(printf "%s\n" "${ACTIVE_PLUGINS[@]}")" | sort -u))
