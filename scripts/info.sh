#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

eval $(get_config_as 'local_label' "environments.$LOCAL_ENV_KEY.label")
eval $(get_config_as 'remote_label' "environments.$REMOTE_ENV_KEY.label")
eval $(get_config_path_as local_basepath "environments.$LOCAL_ENV_KEY.base_path")
eval $(get_config_as remote_basepath "environments.$REMOTE_ENV_KEY.base_path")

eval $(get_config_keys_as -a 'keys' "environments")
for key in "${keys[@]}"; do
  eval $(get_config_as -a 'id' "environments.${key}.id")
  eval $(get_config_as -a 'label' "environments.${key}.label")
  eval $(get_config_as -a 'write_access' "environments.${key}.write_access")
  eval $(get_config_as -a 'plugin' "environments.${key}.plugin")
  eval $(get_config_as -a 'ssh' "environments.${key}.ssh")
  eval $(get_config_path_as -a 'basepath' "environments.${key}.base_path")

  echo_title "$(string_ucfirst $id) Environment: $label"
  table_add_row "SSH" "$ssh"
  table_add_row "Writeable" "$write_access"
  table_add_row "Plugin" "$plugin"
  table_add_row "Root" "$basepath"
  echo_slim_table

  # List out the file groups and paths.

  for group_id in "${FILE_GROUP_IDS[@]}"; do
    eval $(get_config_as group_path "environments.${key}.files.${group_id}")
    if [[ "$group_path" ]]; then
      table_add_row "$group_id" "$group_path"
    fi
  done
  if table_has_rows; then
    table_set_header "File group" "Location"
    echo_slim_table
  fi
done


eval $(get_config_keys_as -a 'keys' "databases")
if [[ ${#keys[@]} -gt 0 ]]; then
  echo
  echo_title "Databases"
  list_clear
  for key in "${keys[@]}"; do
    eval $(get_config_as -a 'id' "databases.${key}.id")
    list_add_item "$id"
  done
  echo_list
  echo
fi

eval $(get_config_keys_as -a 'keys' "file_groups")
if [[ ${#keys[@]} -gt 0 ]]; then
  echo
  echo_title "File Groups"
  list_clear
  for key in "${keys[@]}"; do
    eval $(get_config_as -a 'id' "file_groups.${key}.id")
    list_add_item "$id"
  done
  echo_list
  echo
fi

echo_title "Plugins"
table_set_header "operation" "plugin"
table_add_row "Pull db" "$PLUGIN_PULL_DB"
table_add_row "Pull files" "$PLUGIN_PULL_FILES"
table_add_row "Export local db" "$PLUGIN_EXPORT_LOCAL_DB"
table_add_row "Import to local db" "$PLUGIN_IMPORT_TO_LOCAL_DB"

#echo_title "Other info"
#array_csv__array=("${ACTIVE_PLUGINS[@]}")
#table_add_row "All active plugins" "$(array_csv --prose)"
echo_slim_table

# Plugins may leverage "table_add_row" to build up the More info.  The table is
# echoed by the controller.

