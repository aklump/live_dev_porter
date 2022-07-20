#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

eval $(get_config_as 'local_label' "environments.$LOCAL_ENV_ID.label")
eval $(get_config_as 'remote_label' "environments.$REMOTE_ENV_ID.label")

environment_ids=("$LOCAL_ENV_ID")
[[ "$REMOTE_ENV_ID" != null ]] && environment_ids=("${environment_ids[@]}" "$REMOTE_ENV_ID")

for id in "${environment_ids[@]}"; do
  eval $(get_config_as -a 'label' "environments.$id.label")
  eval $(get_config_as -a 'write_access' "environments.$id.write_access")
#  eval $(get_config_as -a 'plugin' "environments.$id.plugin")
  eval $(get_config_as -a 'ssh' "environments.$id.ssh")
  base_path=$(environment_path_resolve "$id")

  perspective="Local"
  [[ "$id" == "$REMOTE_ENV_ID" ]] && perspective="Remote"

  echo_title "$perspective Environment ($id) : $label"
  [[ "$ssh" ]] && table_add_row "SSH" "$ssh"
  if [[ "$id" == "$LOCAL_ENV_ID" ]]; then
    table_add_row "Root" "$(echo_red_path_if_nonexistent "$base_path")"
  else
    table_add_row "Root" "$base_path"
  fi
  table_add_row "Writeable" "$write_access"
#  table_add_row "Plugin" "$plugin"

  echo_slim_table

  # List out the environment's databases
  eval $(get_config_keys_as database_ids "environments.$id.databases")
  for database_id in "${database_ids[@]}"; do
    eval $(get_config_as plugin "environments.$id.databases.${database_id}.plugin")
    dumpfiles_dir="$(database_get_dumpfiles_directory "$id" "$database_id")"
    table_add_row "$database_id" "$plugin" "$dumpfiles_dir"
  done
  if table_has_rows; then
    table_set_header "DATABASE" "PLUGIN" "EXPORTS"
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
      if [[ "$id" == "$LOCAL_ENV_ID" ]]; then
        table_add_row "$group_id" "$(echo_red_path_if_nonexistent "$group_path")"
      else
        table_add_row "$group_id" "$group_path"
      fi
    fi
  done
  if table_has_rows; then
    table_set_header "FILE GROUP" "PATH"
    echo_slim_table
  fi
done


#eval $(get_config_keys_as -a 'ids' "file_groups")
#if [[ ${#ids[@]} -gt 0 ]]; then
#  echo
#  echo_title "File Groups"
#  list_clear
#  for id in "${ids[@]}"; do
#    list_add_item "$id"
#  done
#  echo_list
#  echo
#fi

#echo_title "Plugins"
#array_csv__array=("${ACTIVE_PLUGINS[@]}")
#table_add_row "All active plugins" "$(array_csv --prose)"
#echo_slim_table

echo_title "Workflows"
eval $(get_config_keys_as workflows "workflows")
for workflow_id in "${workflows[@]}"; do
   table_add_row "$workflow_id"
done
echo_slim_table
