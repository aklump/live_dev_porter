#!/usr/bin/env bash

function mysql_init() {
  _generate_db_cnf || return 1
}

function mysql_test() {
  local defaults_file=$(ldp_get_db_creds_path)
  [ -f "$defaults_file" ] || _generate_db_cnf || return 1
  eval $(get_config_as "db_name" "environments.dev.database.name")
  local message="Connect to local database \"$db_name\""
  if mysql --defaults-file="$defaults_file" "$db_name" -e ";" 2> /dev/null ; then
    echo_pass "$message"
  else
    echo_fail "$message" && fail
  fi
}

function mysql_db_shell() {
  local defaults_file=$(ldp_get_db_creds_path)
  [ -f "$defaults_file" ] || _generate_db_cnf || return 1
  eval $(get_config_as "db_name" "environments.dev.database.name")
  mysql --defaults-file="$defaults_file" "$db_name"
}

function mysql_export_db() {
  local path_to_dumpfile="$1"
  eval $(get_config_as "db_name" "environments.dev.database.name")
  local save_as="$EXPORT_DB_PATH/$db_name.$(date8601 -c).sql"
  local path_to_db_creds=$(ldp_get_db_creds_path)
  [ -f "$path_to_db_creds" ] || _generate_db_cnf || return 1

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

  if [ -f "$path_to_dumpfile" ]; then
    fail_because "Import file \"$path_to_dumpfile\" does not exist." && return 1
  fi


  throw "$path_to_dumpfile;$0;in function ${FUNCNAME}();$LINENO"

}

function mysql_reset_db() {
  local dumpfile=$(ldp_get_fetched_db_path)
  mysql_import_db "$dumpfile"
}

##
# Generate the local.cnf with db creds.
#
function _generate_db_cnf() {
  eval $(get_config_as "host" "environments.dev.database.host")
  eval $(get_config_as "port" "environments.dev.database.port")
  eval $(get_config_as "user" "environments.dev.database.user")
  eval $(get_config_as "pass" "environments.dev.database.pass")

  # Handle the mysql protocol.
  eval $(get_config_as "protocol" "environments.dev.database.protocol")
  if [[ ! "$protocol" ]]; then
    protocol='tcp'
    if [[ "$host" == 'localhost' ]] || [[ "$host" == '127.0.0.1' ]]; then
      protocol='socket'
    fi
  fi

  local path_to_db_creds=$(ldp_get_db_creds_path)
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
  echo "password=\"$pass\"" >>"$path_to_db_creds"
  echo "protocol=\"$protocol\"" >>"$path_to_db_creds"
  chmod 400 "$path_to_db_creds"
}
