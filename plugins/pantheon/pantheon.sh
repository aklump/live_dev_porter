#!/usr/bin/env bash

#
# @file
# Define the Pantheon Plugin
#

function _get_remote_env() {
  case $REMOTE_ENV_ID in
  production)
    echo 'live' && return 0
    ;;
  staging)
    echo 'test' && return 0
    ;;
  esac
  exit_with_failure "Cannot determine Pantheon environment using $REMOTE_ENV_ID"
}

function pantheon_authenticate() {
  eval $(get_config_as 'machine_token' "environments.$REMOTE_ENV_ID.fetch.machine_token")
  exit_with_failure_if_empty_config 'machine_token' 'pantheon.machine_token'

  lando terminus auth:login --machine-token $machine_token
}

function pantheon_remote_clear_cache() {
  eval $(get_config_as 'site_name' "environments.$REMOTE_ENV_ID.fetch.site_name")
  exit_with_failure_if_empty_config 'site_name' 'pantheon.site_name'
  lando terminus env:clear-cache $site_name.$(_get_remote_env)
}

function pantheon_fetch_db() {
  ldp_delete_fetched_db
  local lando_path=$(get_container_path "$FETCH_DB_PATH")
  if [[ ! "$lando_path" ]]; then
    fail_because "Cannot determine \$lando_path for $FETCH_DB_PATH"
    return 1
  fi
  eval $(get_config_as 'site_name' "environments.$REMOTE_ENV_ID.fetch.site_name")
  lando terminus backup:get $site_name.$(_get_remote_env) --element=database --to="$lando_path"
}

function pantheon_remote_shell() {
  eval $(get_config_as 'site_uuid' "environments.$REMOTE_ENV_ID.fetch.site_uuid")
  exit_with_failure_if_empty_config 'site_uuid' 'pantheon.site_uuid'
  sftp -o Port=2222 $(_get_remote_env).$site_uuid@appserver.$(_get_remote_env).$site_uuid.drush.in
}

function pantheon_fetch_files() {
  eval $(get_config_as 'site_uuid' "environments.$REMOTE_ENV_ID.fetch.site_uuid")
  exit_with_failure_if_empty_config 'site_uuid' 'pantheon.site_uuid'

  # @link https://linux.die.net/man/1/rsync
  local rsync_options="-rlz --copy-unsafe-links --size-only --checksum --ipv4"
  has_option v && rsync_options="$rsync_options --progress"

  eval $(get_config_keys_as -a sync_groups files)
  for group in "${sync_groups[@]}"; do
    has_option group && [[ "$(get_option group)" != "$group" ]] && continue
    echo_heading "Fetching \"$group\" files..."
    eval $(get_config_as -a subdirs files.$group)
    [ -d "$FETCH_FILES_PATH/$group" ] || mkdir -p "$FETCH_FILES_PATH/$group"
    for subdir in "${subdirs[@]}"; do
      local local_path=$(combo_path_get_local "$subdir")
      local_path=$(path_resolve "$FETCH_FILES_PATH/$group" "$local_path")
      [ -d "$local_path" ] || mkdir -p "$local_path"
      local remote_path=$(combo_path_get_remote "$subdir")

      local exclude_from="$FETCH_FILES_PATH/$group.ignore.txt"
      rsync $rsync_options -e 'ssh -p 2222' $(_get_remote_env).$site_uuid@appserver.$(_get_remote_env).$site_uuid.drush.in:$remote_path/ "$local_path/" --exclude-from="$exclude_from" || fail

      local message="📦 $(combo_path_get_local "$subdir") ⬅️ 🌎 $(combo_path_get_remote "$subdir")"
      ! has_failed && echo_pass "$message"
      has_failed && echo_fail "$message"
    done
  done
  has_failed && return 1
  return 0
}

function pantheon_info() {
  eval $(get_config_as 'machine_token' "environments.$REMOTE_ENV_ID.fetch.machine_token")
  eval $(get_config_as 'site_uuid' "environments.$REMOTE_ENV_ID.fetch.site_uuid")
  eval $(get_config_as 'site_name' "environments.$REMOTE_ENV_ID.fetch.site_name")

  echo
  echo_heading "Pantheon"
  echo_key_value "Machine token" "$machine_token"
  echo_key_value "$(string_ucfirst "$REMOTE_ENV_ID") Site name" "$site_name"
  echo_key_value "$(string_ucfirst "$REMOTE_ENV_ID") Site UUID" "$site_uuid"
}
