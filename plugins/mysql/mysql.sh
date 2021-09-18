#!/usr/bin/env bash

function mysql_on_clear_cache() {
  local environments=("$LOCAL_ENV_ID" "$REMOTE_ENV_ID")
  for env in "${environments[@]}"; do
    local outfile=$(ldp_get_db_creds_path "$env")
    if [ -f "$outfile" ]; then
      rm -f "$outfile" || return 1
    fi
    succeed_because $(echo_green "$(path_unresolve "$CACHE_DIR" "$outfile")")
  done
  return 0
}

function mysql_on_before_command() {
  # Generate DB credentials for all environments that indicate a db name.
  local environments=("$LOCAL_ENV_ID" "$REMOTE_ENV_ID")
  for env_id in "${environments[@]}"; do
    local outfile=$(ldp_get_db_creds_path "$env_id")
    if [ ! -f "$outfile" ]; then
      eval $(get_config_as "name" "environments.$env_id.database.name")
      if [[ "$name" ]] && ! _generate_db_cnf "$env_id"; then
        fail_because "Could not generate \"$outfile\"."
        return 1
      fi
    fi
  done
  return 0
}

function mysql_configtest() {
  local defaults_file=$(ldp_get_db_creds_path dev)
  eval $(get_config_as "db_name" "environments.dev.database.name")
  local message="Connect to local database \"$db_name\""
  if mysql --defaults-file="$defaults_file" "$db_name" -e ";" 2> /dev/null ; then
    echo_pass "$message"
  else
    echo_fail "$message" && fail
  fi
}

function mysql_db_shell() {
  local defaults_file=$(ldp_get_db_creds_path dev)
  eval $(get_config_as "db_name" "environments.dev.database.name")

  mysql --defaults-file="$defaults_file" "$db_name"
}

function mysql_export_db() {
  local path_to_dumpfile="$1"
  eval $(get_config_as "db_name" "environments.dev.database.name")
  local save_as="$EXPORT_DB_PATH/$db_name.$(date8601 -c).sql"
  local path_to_db_creds=$(ldp_get_db_creds_path dev)

  # First make sure the file does not exist.
  if [ -f "$save_as" ]; then
    rm "$save_as" || fail_because "$save_as exists and cannot be deleted"
    return 1
  fi

  # @link https://zoomadmin.com/HowToLinux/LinuxCommand/mysqldump
  eval $(get_config_as -a 'settings' 'environments.dev.export.mysqldump_options')

  local shared_options
  if [[ null != ${settings[@]} ]]; then
    for option in ${settings[@]}; do
      shared_options=" $shared_options --$option"
    done
  fi

  # Dump create table structure
  local structure_tables=$(ldp_get_db_export_structure_and_data_tables)
  if [[ "$structure_tables" ]]; then
    local options="$shared_options --add-drop-table --no-data "
    mysqldump --defaults-file="$path_to_db_creds"$options "$db_name" $structure_tables >> "$save_as"
  fi

  # Dump table data
  local data_tables=$(ldp_get_db_export_data_only_tables)
  if [[ "$data_tables" ]]; then
    local options="$shared_options --skip-add-drop-table --no-create-info"
    mysqldump --defaults-file="$path_to_db_creds"$options "$db_name" $data_tables >> "$save_as"
  fi

  if [[ ! "$structure_tables" ]] || [[ ! "$data_tables" ]]; then
    fail_because "No tables to be exported"
  fi

  has_failed && return 1
  succeed_because "Saved to $save_as"
}

function mysql_import_db() {
  local path_to_dumpfile="$1"

  if [[ ! "$path_to_dumpfile" ]]; then
    fail_because "No import filename given." && return 1
  fi
  if [ ! -f "$path_to_dumpfile" ]; then
    fail_because "Import file \"$path_to_dumpfile\" does not exist." && return 1
  fi

  eval $(get_config_as "db_name" "environments.dev.database.name")
  local path_to_db_creds=$(ldp_get_db_creds_path dev)

  mysql --defaults-file="$path_to_db_creds" $db_name < $path_to_dumpfile
}

function mysql_reset_db() {
  local dumpfile=$(ldp_get_fetched_db_path)
  mysql_import_db "$dumpfile"
}

##
# Generate the local.cnf with db creds.
#
# $1 - the environment id, e.g. 'dev', 'production'.
#
function _generate_db_cnf() {
  local env_id=$1

  eval $(get_config_as "host" "environments.$env_id.database.host")
  [[  "$host" ]] || host="localhost"

  eval $(get_config_as "port" "environments.$env_id.database.port")
  [[  "$port" ]] || port="3306"

  eval $(get_config_as "user" "environments.$env_id.database.user")
  exit_with_failure_if_empty_config "user" "environments.$env_id.database.user"

  eval $(get_config_as "password" "environments.$env_id.database.password")
  exit_with_failure_if_empty_config "password" "environments.$env_id.database.user"

  # Handle the mysql protocol.
  eval $(get_config_as "protocol" "environments.$env_id.database.protocol")
  if [[ ! "$protocol" ]]; then
    protocol='tcp'
    # TODO Need to do more research on this. Sep 17, 2021, aklump.
#    if [[ "$host" == 'localhost' ]] || [[ "$host" == '127.0.0.1' ]]; then
#      protocol='socket'
#    fi
  fi

  local path_to_db_creds=$(ldp_get_db_creds_path "$env_id")
  if ! touch "$path_to_db_creds" || ! chmod 0600 "$path_to_db_creds"; then
    fail_because "Could not create $path_to_db_creds"
    return 1
  fi

  # Create the .cnf file
  echo "# AUTOGENERATED, DO NOT EDIT!" >"$path_to_db_creds"
  echo "[client]" >>"$path_to_db_creds"
  echo "host=\"$host\"" >>"$path_to_db_creds"
  [ "$port" ] && echo "port=\"$port\"" >>"$path_to_db_creds"
  echo "user=\"$user\"" >>"$path_to_db_creds"
  echo "password=\"$password\"" >>"$path_to_db_creds"
  echo "protocol=\"$protocol\"" >>"$path_to_db_creds"
  chmod 400 "$path_to_db_creds"
}
