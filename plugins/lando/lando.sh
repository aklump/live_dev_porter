#!/usr/bin/env bash

function _lando_on_boot() {
  [ -e "$APP_ROOT/.lando.yml" ] || return 0
  local name=$(grep name: < "$APP_ROOT/.lando.yml")
  LANDO_APP_NAME=${name/name: /}
}

function lando_on_configtest() {
  throw ";$0;in function ${FUNCNAME}();$LINENO"
  local running
  local assert

  # Assert we have a lando app name.
  assert="Lando app identified as \"$LANDO_APP_NAME\"."
  if [[ ! "$LANDO_APP_NAME" ]]; then
    echo_fail "$assert" && fail
  else
    echo_pass "$assert"
  fi

  # Assert that app is running.
  local message="\"$LANDO_APP_NAME\" is running"
  if [[ ! "$LANDO_APP_NAME" ]] || [[ "$(lando list --app $LANDO_APP_NAME)" == "[]" ]]; then
    echo_fail "$message" && fail
  else
    echo_pass "$message"
  fi
}

function lando_on_clear_cache() {
  database_delete_all_defaults_files || return 1
  database_delete_all_name_files || return 1
  return 0
}

# Convert lando database to yml file for config API.
#
function lando_on_rebuild_config() {
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_ID.databases")
  for database_id in "${database_ids[@]}"; do
    local db_pointer="environments.$LOCAL_ENV_ID.databases.${database_id}"
    eval $(get_config_as "plugin" "$db_pointer.plugin")
    [[ "$plugin" != 'lando' ]] && continue;

    eval $(get_config_as service "$db_pointer.service")

    ! json_set "$(cd $APP_ROOT && lando info -s $service --format=json | tail -1)" && fail_because "Could not read Lando configuration" && return 1

    local filepath=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
    local path_label="$(path_unresolve "$APP_ROOT" "$filepath")"

    # Create the .cnf file
    local directory=""$(dirname "$filepath")""
    sandbox_directory "$directory"
    ! mkdir -p "$directory" && fail_because "Could not create $directory" && return 1
    ! touch "$filepath" && fail_because "Could not create $path_label" && return 1
    ! chmod 0600 "$filepath" && fail_because "Failed with chmod 0600 $path_label" && return 1

    local host="$(json_get_value '0.external_connection.host')"
    local port="$(json_get_value '0.external_connection.port')"
    local user="$(json_get_value '0.creds.user')"
    local password="$(json_get_value '0.creds.password')"

    echo "[client]" >"$filepath"
    echo "host=\"$host\"" >>"$filepath"
    [[ "$port" ]] && echo "port=\"$port\"" >>"$filepath"
    echo "user=\"$user\"" >>"$filepath"
    echo "password=\"$password\"" >>"$filepath"
    [[ "$protocol" ]] && echo "protocol=\"$protocol\"" >>"$filepath"
    ! chmod 0400 "$filepath" && fail_because "Failed with chmod 0400 $path_label" && return 1

    # Save the database name
    name_path="$(database_get_cached_name_filepath "$LOCAL_ENV_ID" "$database_id")"
    local name_label="$(path_unresolve "$APP_ROOT" "$name_path")"
    echo "$(json_get_value '0.creds.database')" > $name_path
    succeed_because "$name_label has been created."
  done
  has_failed && return 1
  succeed_because "$path_label has been created."
  return 0
}

# @see database_get_name
function lando_on_database_name() {
  local environment_id="$1"
  local database_id="$2"

  local db_name
  local filepath
  filepath="$(database_get_cached_name_filepath "$environment_id" "$database_id")"
  [[ ! -f "$filepath" ]] && echo "Missing database name; try clearing caches." && return 1
  db_name=$(cat "$filepath")
  [[ "$db_name" ]] && echo "$db_name" && return 0
  echo "Lando cannot determine the database name" && return 1
}

function lando_on_db_shell() {
  call_plugin mysql db_shell $@
}
function lando_on_export_db() {
  call_plugin mysql export_db $@
}
function lando_on_import_db() {
  call_plugin mysql import_db $@
}
function lando_on_pull_db() {
  call_plugin mysql pull_db $@
}
