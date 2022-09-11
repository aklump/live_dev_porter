#!/usr/bin/env bash

#
# @file
# Generate the "info" route output
#

eval $(get_config_as 'local_label' "environments.$LOCAL_ENV_ID.label")
eval $(get_config_as 'remote_label' "environments.$REMOTE_ENV_ID.label")

for id in "${ACTIVE_ENVIRONMENTS[@]}"; do
  eval $(get_config_as -a 'label' "environments.$id.label")
  eval $(get_config_as -a 'write_access' "environments.$id.write_access")
#  eval $(get_config_as -a 'plugin' "environments.$id.plugin")
  eval $(get_config_as -a 'ssh' "environments.$id.ssh")
  base_path=$(environment_path_resolve "$id")

  adjective="Other"
  [[ "$id" == "$LOCAL_ENV_ID" ]] && adjective="Local"
  [[ "$id" == "$REMOTE_ENV_ID" ]] && adjective="Remote"
  echo_title "$adjective Environment ($id) : $label"
  if is_ssh_connection "$id"; then
    table_add_row "Root" "$base_path"
    if [[ "$ssh" ]]; then
      table_add_row "SSH" "$ssh"
      table_add_row "scp" "$ssh:$base_path"
    fi
  else
    table_add_row "Root" "$(echo_red_path_if_nonexistent "$base_path")"
  fi
  table_add_row "Writeable" "$write_access"
#  table_add_row "Plugin" "$plugin"

  echo_slim_table

  # List out the environment's databases
  eval $(get_config_keys_as database_ids "environments.$id.databases")
  for database_id in "${database_ids[@]}"; do
    eval $(get_config_as plugin "environments.$id.databases.${database_id}.plugin")
    if [[ "$id" == "$LOCAL_ENV_ID" ]]; then
      dumpfiles_dir="$(database_get_local_directory "$id" "$database_id")"
      table_add_row "$database_id" "$plugin" "$dumpfiles_dir"
    else
      table_add_row "$database_id" "$plugin"
    fi
  done
  if table_has_rows; then
    if [[ "$id" == "$LOCAL_ENV_ID" ]]; then
      table_set_header "DATABASE" "PLUGIN" "EXPORTS"
    else
      table_set_header "DATABASE" "PLUGIN"
    fi
    echo_slim_table
  fi

  # List out the file groups and paths.
  eval $(get_config_keys_as -a 'file_groups' "file_groups")
  for group_id in "${file_groups[@]}"; do
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

#echo_title "Plugins"
#array_csv__array=("${ACTIVE_PLUGINS[@]}")
#table_add_row "All active plugins" "$(array_csv --prose)"
#echo_slim_table

echo_title "Active Environments"
for environment_id in "${ACTIVE_ENVIRONMENTS[@]}"; do
   table_add_row "$environment_id"
done
echo_slim_table

echo_title "Workflows"
eval $(get_config_keys_as workflows "workflows")
for workflow_id in "${workflows[@]}"; do
  table_set_header "ID" "DATABASES" "FILE GROUPS" "PROCESSORS"
  eval $(get_config_keys_as databases "workflows.$workflow_id.databases")
  eval $(get_config_as -a file_groups "workflows.$workflow_id.file_groups")
  eval $(get_config_as -a processors "workflows.$workflow_id.processors")

  max=$(( ${#databases[@]} > ${#file_groups[@]} ? ${#databases[@]} : ${#file_groups[@]}))
  max=$(( $max > ${#processors[@]} ? $max : ${#processors[@]}))
  label=$workflow_id
  for (( i = 0; i < $max; i++ )); do
    table_add_row "$label" "${databases[$i]}" "${file_groups[$i]}" "${processors[$i]}"
    label=''
  done
  echo_slim_table
  echo
done

