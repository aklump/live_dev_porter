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

eval $(get_config_as LOCAL_PLUGIN "environments.$LOCAL_ENV_KEY.plugin")
[[ "$LOCAL_PLUGIN" ]] || LOCAL_PLUGIN="default"
eval $(get_config_as REMOTE_PLUGIN "environments.$REMOTE_ENV_KEY.plugin")
[[ "$REMOTE_PLUGIN" ]] || REMOTE_PLUGIN="default"

eval $(get_config_as PLUGIN_PULL_DB 'plugin_assignments.pull.db')
PLUGIN_PULL_DB=$(_token_expand $PLUGIN_PULL_DB)

eval $(get_config_as PLUGIN_PULL_FILES 'plugin_assignments.pull.files')
PLUGIN_PULL_FILES=$(_token_expand $PLUGIN_PULL_FILES)

eval $(get_config_as PLUGIN_EXPORT_LOCAL_DB 'plugin_assignments.export.db')
PLUGIN_EXPORT_LOCAL_DB=$(_token_expand $PLUGIN_EXPORT_LOCAL_DB)

eval $(get_config_as PLUGIN_IMPORT_TO_LOCAL_DB 'plugin_assignments.import.db')
PLUGIN_IMPORT_TO_LOCAL_DB=$(_token_expand $PLUGIN_IMPORT_TO_LOCAL_DB)

eval $(get_config_as PLUGIN_LOCAL_DB_SHELL 'plugin_assignments.shell.db')
PLUGIN_LOCAL_DB_SHELL=$(_token_expand $PLUGIN_LOCAL_DB_SHELL)

eval $(get_config_as PLUGIN_REMOTE_SSH_SHELL 'plugin_assignments.shell.remote')
PLUGIN_REMOTE_SSH_SHELL=$(_token_expand $PLUGIN_REMOTE_SSH_SHELL)

# Create a unique list of active plugins.
declare -a ACTIVE_PLUGINS=($PLUGIN_PULL_DB $PLUGIN_PULL_FILES $PLUGIN_EXPORT_LOCAL_DB $PLUGIN_IMPORT_TO_LOCAL_DB $PLUGIN_LOCAL_DB_SHELL $PLUGIN_REMOTE_SSH_SHELL)
ACTIVE_PLUGINS=($(echo "$(printf "%s\n" "${ACTIVE_PLUGINS[@]}")" | sort -u))
