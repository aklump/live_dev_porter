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
  base_path=$(environment_path_resolve "$id") && base_path_short=$(path_make_pretty "$base_path")

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
    table_add_row "Root" "$(echo_red_path_if_nonexistent "$base_path" "$base_path_short")"
  fi
  table_add_row "Writeable" "$write_access"
#  table_add_row "Plugin" "$plugin"

  table_set_column_widths 18
  echo_slim_table

  # List out the environment's databases
  eval $(get_config_keys_as database_ids "environments.$id.databases")
  first_db=true
  for database_id in "${database_ids[@]}"; do
    if [[ $first_db != true ]]; then
      table_add_row
    fi
    eval $(get_config_as plugin "environments.$id.databases.${database_id}.plugin")
    table_add_row "ID" "$database_id"
    table_add_row "plugin" "$plugin"
    if [[ "$id" == "$LOCAL_ENV_ID" ]]; then
      table_add_row "connection" "$(database_get_connection_url "$id" "$database_id")"
      dumpfiles_dir="$(database_get_local_directory "$id" "$database_id")"
      table_add_row "exports" "$(path_make_pretty "$dumpfiles_dir")"
    fi
    first_db=false
  done
  if table_has_rows; then
    table_set_header "DATABASES"
    table_set_column_widths 18
    echo_slim_table
  fi

  # List out the file groups and paths.
  eval $(get_config_keys_as -a 'file_groups' "file_groups")
  for group_id in "${file_groups[@]}"; do
    eval $(get_config_as group_path "environments.$id.files.${group_id}")
    if [[ "$group_path" ]]; then
      group_path="$(path_make_absolute "$group_path" "$base_path")"
      group_path=${group_path%/}
      group_path=${group_path%.}
      group_path=${group_path%/}
      if [[ "$id" == "$LOCAL_ENV_ID" ]]; then
        group_path_short=$(path_make_pretty "$group_path")
      else
        group_path_short="$group_path"
      fi
      if is_ssh_connection "$id"; then
        table_add_row "$group_id" "$group_path_short"
      else
        table_add_row "$group_id" "$(echo_red_path_if_nonexistent "$group_path" "$group_path_short")"
      fi
    fi
  done
  if table_has_rows; then
    table_set_header "FILE GROUP" "PATH"
    table_set_column_widths 18
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
table_set_column_widths 18
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
  table_set_column_widths 18
  echo_slim_table
  echo
done

