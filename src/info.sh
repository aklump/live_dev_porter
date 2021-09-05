#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

echo_title "Live Dev Porter Configuration"

eval $(get_config_as 'local_name' "environments.$LOCAL_ENV_ID.name")
echo_key_value 'Local:' "$(string_upper $LOCAL_ENV) - $local_name"

eval $(get_config_as 'remote_name' "environments.$REMOTE_ENV_ID.name")
echo_key_value 'Remote:' "$(string_upper $REMOTE_ENV) - $remote_name"

echo_key_value 'Fetched Database:' $(path_unresolve $APP_ROOT $PULL_DB_PATH)
echo_key_value 'Fetched Files:' $(path_unresolve $APP_ROOT $PULL_FILES_PATH)
