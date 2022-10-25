#!/usr/bin/env bash

# Echos the filepath that stores the cached git branch.
#
# $1 - environment_id
# $2 - database_id
#
function lando_git_get_cached_branch_filepath() {
  local environment_id="$1"
  local database_id="$2"

  local filepath
  filepath=$(database_get_defaults_file "$environment_id" "$database_id")
  echo "$(dirname $filepath)/git_branch.txt"
}

# Echo the active git branch based on the app root.
#
function lando_git_get_active_git_branch() {
  (cd "$APP_ROOT" && git rev-parse --abbrev-ref HEAD)
}

function lando_git_on_clear_cache() {
  database_delete_all_defaults_files || return 1
  database_delete_all_name_files || return 1

  local pattern
  pattern=$(lando_git_get_cached_branch_filepath "*" "*")
  for filepath in $pattern; do
    [[ ! -f "$filepath" ]] && continue
    sandbox_directory "$(dirname $filepath)"
    if chmod 0600 "$filepath" && rm "$filepath"; then
      succeed_because "$(path_unresolve "$APP_ROOT" "$filepath")"
    else
      fail_because "Failed to delete $filepath"
    fi
  done
  has_failed && return 1
  return 0
}

function lando_git_on_db_shell() {
  call_plugin mysql db_shell "$@"
}
function lando_git_on_export_db() {
  call_plugin mysql export_db "$@"
}
function lando_git_on_import_db() {
  call_plugin mysql import_db "$@"
}
function lando_git_on_pull_db() {
  call_plugin mysql pull_db "$@"
}

# Convert lando database to yml file for config API.
#
function lando_git_on_rebuild_config() {
  local db_pointer
  local directory
  local filepath
  local host
  local name_label
  local password
  local path_label
  local port
  local user
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_ID.databases")
  for database_id in "${database_ids[@]}"; do
    local db_pointer="environments.$LOCAL_ENV_ID.databases.${database_id}"
    eval $(get_config_as "plugin" "$db_pointer.plugin")
    [[ "$plugin" != 'lando_git' ]] && continue;

    eval $(get_config_keys_as -a branches "$db_pointer.service_by_branch")

    local active_git_branch="$(lando_git_get_active_git_branch)"
    eval $(get_config_as service "$db_pointer.service_by_branch.$active_git_branch")

    if [[ ! "$service" ]]; then
      fail_because "The active git branch $active_git_branch is not mapped to a lando database service in your configuration";
      return 1
    fi

    # Make note of the active branch on which these creds were loaded so we can
    # compare later in case the branch changes.
    filepath=$(lando_git_get_cached_branch_filepath "$LOCAL_ENV_ID" "$database_id")
    echo "$active_git_branch" > "$filepath"

    ! json_set "$(cd $APP_ROOT && lando info -s $service --format=json 2>/dev/null | tail -1)" && fail_because "Could not read Lando configuration" && return 1

    filepath=$(database_get_defaults_file "$LOCAL_ENV_ID" "$database_id")
    path_label="$(path_unresolve "$APP_ROOT" "$filepath")"

    # Create the .cnf file
    directory=""$(dirname "$filepath")""
    sandbox_directory "$directory"
    ! mkdir -p "$directory" && fail_because "Could not create $directory" && return 1
    ! touch "$filepath" && fail_because "Could not create $path_label" && return 1
    ! chmod 0600 "$filepath" && fail_because "Failed with chmod 0600 $path_label" && return 1

    host="$(json_get_value '0.external_connection.host')"
    port="$(json_get_value '0.external_connection.port')"
    user="$(json_get_value '0.creds.user')"
    password="$(json_get_value '0.creds.password')"

    echo "[client]" >"$filepath"
    echo "host=\"$host\"" >>"$filepath"
    [[ "$port" ]] && echo "port=\"$port\"" >>"$filepath"
    echo "user=\"$user\"" >>"$filepath"
    echo "password=\"$password\"" >>"$filepath"
    [[ "$protocol" ]] && echo "protocol=\"$protocol\"" >>"$filepath"
    ! chmod 0400 "$filepath" && fail_because "Failed with chmod 0400 $path_label" && return 1
    succeed_because "$path_label has been created."

    # Save the database name
    name_path="$(database_get_cached_name_filepath "$LOCAL_ENV_ID" "$database_id")"
    name_label="$(path_unresolve "$APP_ROOT" "$name_path")"
    echo "$(json_get_value '0.creds.database')" > $name_path || return 1
    succeed_because "$name_label has been created."
  done
  has_failed && return 1
  return 0
}

# @see database_get_name
function lando_git_on_database_name() {
  local environment_id="$1"
  local database_id="$2"

  local active_git_branch
  local cached_git_branch
  local db_name
  local filepath

  active_git_branch=$(lando_git_get_active_git_branch)

  filepath="$(lando_git_get_cached_branch_filepath "$environment_id" "$database_id")"
  cached_git_branch=$(cat "$filepath")
  if [[ "$active_git_branch" != "$cached_git_branch" ]]; then
    echo "The git branch has changed; clear caches to reload the database connection." && return 1
  fi

  filepath="$(database_get_cached_name_filepath "$environment_id" "$database_id")"
  [[ ! -f "$filepath" ]] && echo "Missing database name; try clearing caches." && return 1
  db_name=$(cat "$filepath")
  [[ "$db_name" ]] && echo "$db_name" && return 0
  echo "Lando cannot determine the database name" && return 1
}

function lando_git_on_configtest() {
  local lando_file
  local name
  local run_lando_tests
  run_lando_tests=false
  eval $(get_config_keys_as "database_ids" "environments.$LOCAL_ENV_ID.databases")
  for database_id in "${database_ids[@]}"; do
    eval $(get_config_as "plugin" "environments.$LOCAL_ENV_ID.databases.${database_id}.plugin")
    [[ "$plugin" == 'lando_git' ]] && run_lando_tests=true && break
  done
  [[ "$run_lando_tests" == false ]] && return 255

  lando_file="$APP_ROOT/.lando.yml"
  echo_task "Can read Lando file: $lando_file"
  ! [[ -f "$lando_file" ]] && echo_task_failed && fail && return 1

  name=$(grep name: < "$lando_file")
  LANDO_APP_NAME=${name/name: /}
  ! [[ "$LANDO_APP_NAME" ]] && echo_task_failed && fail && return 1
  echo_task_completed

  echo_task "Assert \"$LANDO_APP_NAME\" is running."
  if [[ "$(lando list --app "$LANDO_APP_NAME")" == "[]" ]]; then
    echo_task_failed && fail
  else
    echo_task_completed
  fi

  call_plugin mysql configtest "$@"
}
