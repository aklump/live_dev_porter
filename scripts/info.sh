#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

echo_title "Live Dev Porter Configuration"

echo
eval $(get_config_as 'local_label' "environments.$LOCAL_ENV_ID.label")
echo_heading "$local_label (local/$LOCAL_ENV)"
echo_key_value Plugin "$DEV_PLUGIN"

echo
eval $(get_config_as 'remote_label' "environments.$REMOTE_ENV_ID.label")
echo_heading "$remote_label (remote/$REMOTE_ENV_ID)"
echo_key_value Plugin "$PRODUCTION_PLUGIN"

echo_key_value 'Fetch DB' $(path_unresolve $APP_ROOT $FETCH_DB_PATH)
echo_key_value 'Fetch files' $(path_unresolve $APP_ROOT $FETCH_FILES_PATH)

echo
echo_heading "Miscellaneous"

array_csv__array=("${ACTIVE_PLUGINS[@]}")
echo_key_value 'Active plugins' "$(array_csv --prose)"

