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

# Get eval snippet for rsync file exclude-from argument.
#
# @code
#   eval $(_get_file_ignore_paths)
# @endcode
#
# Returns 0 if .
function _get_file_ignore_paths() {
  local snippet=$(get_config_as -a 'ignore_paths' "environments.$REMOTE_ENV_ID.fetch.ignore_files_listed_in")
  local find=']="'

  echo "${snippet//$find/$find$CONFIG_DIR/fetch/$REMOTE_ENV/files/}"
}

function pantheon_init() {
  eval $(_get_file_ignore_paths)
  for path in "${ignore_paths[@]}"; do
    if [ ! -f "$path" ]; then
      touch "$path"
      succeed_because "Created: $path"
    fi
  done
}

function pantheon_authenticate() {
  eval $(get_config_as 'machine_token' "environments.$REMOTE_ENV_ID.fetch.machine_token")
  exit_with_failure_if_empty_config 'machine_token' 'pantheon.machine_token'

  lando terminus auth:login --machine-token $token
}

function pantheon_clear_cache() {
  eval $(get_config_as 'site_name' "environments.$REMOTE_ENV_ID.fetch.site_name")
  exit_with_failure_if_empty_config 'site_name' 'pantheon.site_name'

  lando terminus env:clear-cache $site_name.$(_get_remote_env)
}

function pantheon_fetch_db() {
  local lando_path=$(get_container_path "$pull_to_path")/db
  lando terminus backup:get $SITE_NAME.$(_get_remote_env) --element=database --to="$lando_path" --verbose
}

function pantheon_fetch_files() {
  local local_path="$PULL_FILES_PATH/drupal"
  local exclude_from

  eval $(get_config_as 'site_uuid' "environments.$REMOTE_ENV_ID.fetch.site_uuid")
  exit_with_failure_if_empty_config 'site_uuid' 'pantheon.site_uuid'

  mkdir -pv "$local_path" || return 1
  eval $(_get_file_ignore_paths)
  for path in "${ignore_paths[@]}"; do
    exclude_from=" --exclude-from=$path"
  done

  rsync -rlz --copy-unsafe-links --size-only --checksum --ipv4 --progress -e 'ssh -p 2222' $(_get_remote_env).$site_uuid@appserver.$(_get_remote_env).$site_uuid.drush.in:files/ "$local_path"$exclude_from
}

function pantheon_reset_files() {
  local config_key="environments.$LOCAL_ENV_ID.reset.files.drupal"

  eval $(get_config_as 'drupal_files' "$config_key")
  exit_with_failure_if_config_is_not_path 'drupal_files' "$config_key"
  rsync -a "$PULL_FILES_PATH/drupal/" "$drupal_files/"
}

function pantheon_info() {
  eval $(get_config_as 'machine_token' "environments.$REMOTE_ENV_ID.fetch.machine_token")
  eval $(get_config_as 'site_uuid' "environments.$REMOTE_ENV_ID.fetch.site_uuid")
  eval $(get_config_as 'site_name' "environments.$REMOTE_ENV_ID.fetch.site_name")
  echo_key_value "Machine token" "$machine_token"
  echo_key_value "Site name" "$site_name"
  echo_key_value "Site UUID" "$site_uuid"
}
