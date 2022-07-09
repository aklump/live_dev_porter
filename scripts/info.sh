#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

eval $(get_config_as 'local_label' "environments.$LOCAL_ENV_LOOKUP.label")
eval $(get_config_as 'remote_label' "environments.$REMOTE_ENV_LOOKUP.label")
eval $(get_config_path_as local_basepath "environments.$LOCAL_ENV_LOOKUP.base_path")
eval $(get_config_as remote_basepath "environments.$REMOTE_ENV_LOOKUP.base_path")

echo_title "Live Dev Porter Configuration"

echo
echo_heading "Active Environments"


table_set_header "" "$local_label ($LOCAL_ENV_ID)" "$remote_label ($REMOTE_ENV_ID)"
table_add_row "basepath" "$local_basepath" "$remote_basepath"
table_add_row "SSH" "" "$REMOTE_ENV_AUTH"
table_add_row "Plugin" "$DEV_PLUGIN" "$REMOTE_PLUGIN"
echo_slim_table

echo
echo_heading "More info"
array_csv__array=("${ACTIVE_PLUGINS[@]}")
table_add_row "Active plugins" "$(array_csv --prose)"

# Plugins may leverage "table_add_row" to build up the More info.  The table is
# echoed by the controller.

