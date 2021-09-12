#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

echo_title "Live Dev Porter Configuration"

echo
echo_heading "$(string_ucfirst "$LOCAL_ENV")"
eval $(get_config_as 'local_label' "environments.$LOCAL_ENV_ID.label")
echo_key_value 'Local' "$(string_upper $LOCAL_ENV) - $local_label"
echo_key_value Plugin "$DEV_PLUGIN"

echo
echo_heading "$(string_ucfirst "$REMOTE_ENV")"
echo_key_value Plugin "$PRODUCTION_PLUGIN"
eval $(get_config_as 'remote_label' "environments.$REMOTE_ENV_ID.label")
echo_key_value 'Remote' "$(string_upper $REMOTE_ENV) - $remote_label"

echo_key_value 'Fetched database' $(path_unresolve $APP_ROOT $PULL_DB_PATH)
echo_key_value 'Fetched files' $(path_unresolve $APP_ROOT $PULL_FILES_PATH)

echo
echo_heading "Miscellaneous"
echo_key_value 'Active plugins' "${ACTIVE_PLUGINS[*]}"

