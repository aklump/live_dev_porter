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
  value=${value//DEV_PLUGIN/$DEV_PLUGIN}
  value=${value//REMOTE_PLUGIN/$REMOTE_PLUGIN}
  echo "$value"
}

eval $(get_config_as DEV_PLUGIN 'environments.dev.plugin')
[[ "$DEV_PLUGIN" ]] || DEV_PLUGIN="default"
eval $(get_config_as REMOTE_PLUGIN 'environments.production.plugin')
[[ "$REMOTE_PLUGIN" ]] || REMOTE_PLUGIN="default"

eval $(get_config_as PLUGIN_PULL_DB 'plugin_assignments.pull.db')
PLUGIN_PULL_DB=$(_token_expand $PLUGIN_PULL_DB)

eval $(get_config_as PLUGIN_PULL_FILES 'plugin_assignments.pull.files')
PLUGIN_PULL_FILES=$(_token_expand $PLUGIN_PULL_FILES)

eval $(get_config_as PLUGIN_RESET_DB 'plugin_assignments.reset.db')
PLUGIN_RESET_DB=$(_token_expand $PLUGIN_RESET_DB)

eval $(get_config_as PLUGIN_RESET_FILES 'plugin_assignments.reset.files')
PLUGIN_RESET_FILES=$(_token_expand $PLUGIN_RESET_FILES)

eval $(get_config_as PLUGIN_EXPORT_DB 'plugin_assignments.export.db')
PLUGIN_EXPORT_DB=$(_token_expand $PLUGIN_EXPORT_DB)

eval $(get_config_as PLUGIN_IMPORT_DB 'plugin_assignments.import.db')
PLUGIN_IMPORT_DB=$(_token_expand $PLUGIN_IMPORT_DB)

eval $(get_config_as PLUGIN_DB_SHELL 'plugin_assignments.shell.db')
PLUGIN_DB_SHELL=$(_token_expand $PLUGIN_DB_SHELL)

eval $(get_config_as PLUGIN_REMOTE_SHELL 'plugin_assignments.shell.remote')
PLUGIN_REMOTE_SHELL=$(_token_expand $PLUGIN_REMOTE_SHELL)

# Create a unique list of active plugins.
declare -a ACTIVE_PLUGINS=($PLUGIN_PULL_DB $PLUGIN_PULL_FILES $PLUGIN_RESET_DB $PLUGIN_RESET_FILES $PLUGIN_EXPORT_DB $PLUGIN_IMPORT_DB $PLUGIN_DB_SHELL $PLUGIN_REMOTE_SHELL)
ACTIVE_PLUGINS=($(echo "$(printf "%s\n" "${ACTIVE_PLUGINS[@]}")" | sort -u))
