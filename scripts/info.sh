#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

eval $(get_config_as 'local_label' "environments.$LOCAL_ENV_ID.label")
eval $(get_config_as 'remote_label' "environments.$REMOTE_ENV_ID.label")

for id in "${ENVIRONMENT_IDS[@]}"; do
  eval $(get_config_as -a 'label' "environments.$id.label")
  eval $(get_config_as -a 'write_access' "environments.$id.write_access")
  eval $(get_config_as -a 'plugin' "environments.$id.plugin")
  eval $(get_config_as -a 'ssh' "environments.$id.ssh")
  base_path=$(environment_path_resolve "$id")

  echo_title "$(string_ucfirst $id) Environment: $label"
  [[ "$ssh" ]] && table_add_row "SSH" "$ssh"
  table_add_row "Writeable" "$write_access"
  table_add_row "Plugin" "$plugin"
  table_add_row "Root" "$base_path"
  echo_slim_table

  # List out the environment's databases
  eval $(get_config_keys_as database_ids "environments.$id.databases")
  for database_id in "${database_ids[@]}"; do
    eval $(get_config_as plugin "environments.$id.databases.${database_id}.plugin")
    dumpfiles_dir="$(database_get_dumpfiles_directory "$id" "$database_id")"
    table_add_row "$database_id" "$plugin" "$dumpfiles_dir"
  done
  if table_has_rows; then
    table_set_header "Database" "Plugin" "Path"
    echo_slim_table
  fi

  # List out the file groups and paths.
  for group_id in "${FILE_GROUP_IDS[@]}"; do
    eval $(get_config_as group_path "environments.$id.files.${group_id}")
    if [[ "$group_path" ]]; then
      group_path="$(path_resolve "$base_path" "$group_path")"
      group_path=${group_path%/}
      group_path=${group_path%.}
      group_path=${group_path%/}
      table_add_row "$group_id" "$group_path"
    fi
  done
  if table_has_rows; then
    table_set_header "File group" "Path"
    echo_slim_table
  fi
done


eval $(get_config_keys_as -a 'ids' "file_groups")
if [[ ${#ids[@]} -gt 0 ]]; then
  echo
  echo_title "File Groups"
  list_clear
  for id in "${ids[@]}"; do
    list_add_item "$id"
  done
  echo_list
  echo
fi

echo_title "Plugins"
array_csv__array=("${ACTIVE_PLUGINS[@]}")
table_add_row "All active plugins" "$(array_csv --prose)"
echo_slim_table
