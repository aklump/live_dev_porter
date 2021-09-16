#!/usr/bin/env bash

# @file
#
# Default plugin handler
#

function default_configtest() {
  eval $(get_config_keys_as -a array_csv__array files_sync)
  local assert
  assert="File sync groups defined as: $(array_csv --prose --quotes)"
  if [ ${#array_csv__array[@]} -lt 1 ]; then
    echo_fail "$assert" && fail
  else
    echo_pass "$assert"
  fi
}

function default_remote_shell() {
  eval $(get_config_as remote_app_root "environments.$REMOTE_ENV_ID.app_root")

  # @link https://stackoverflow.com/a/14703291/3177610
  # @link https://www.man7.org/linux/man-pages/man1/ssh.1.html
  ssh -t "$(get_remote)" "cd $remote_app_root && bash -i"
}

function default_info() {
  eval $(get_config_as remote_app_root "environments.$REMOTE_ENV_ID.app_root")

  echo_key_value "SSH" "$(get_remote)"
  echo_key_value "$REMOTE_ENV app root" "$remote_app_root"
}

function default_init() {
  ensure_files_sync_local_directories && succeed_because "Updated fetch structure at $(path_unresolve "$APP_ROOT" "$FETCH_FILES_PATH")"
}

function default_fetch_files() {
  eval $(get_config_as remote_app_root "environments.$REMOTE_ENV_ID.app_root")
  exit_with_failure_if_empty_config remote_app_root "environments.$REMOTE_ENV_ID.app_root"

  # @link https://linux.die.net/man/1/rsync
  local rsync_options="-az --copy-unsafe-links --size-only"
  has_option v && rsync_options="$rsync_options --progress"

  eval $(get_config_keys_as -a sync_groups files_sync)
  ensure_files_sync_local_directories
  for group in "${sync_groups[@]}"; do
    has_option group && [[ "$(get_option group)" != "$group" ]] && continue
    echo_heading "Fetching \"$group\" files..."
    eval $(get_config_as -a subdirs files_sync.$group)
    [ -d "$FETCH_FILES_PATH/$group" ] || mkdir -p "$FETCH_FILES_PATH/$group"
    for subdir in "${subdirs[@]}"; do
      local local_path=$(combo_path_get_local "$subdir")
      local_path=$(path_resolve "$FETCH_FILES_PATH/$group" "$local_path")
      [ -d "$local_path" ] || mkdir -p "$local_path"
      local remote_path=$(combo_path_get_remote "$subdir")
      remote_path=$(path_resolve "$remote_app_root" "$remote_path")

      local exclude_from="$FETCH_FILES_PATH/$group.ignore.txt"
      rsync $rsync_options "$(get_remote):$remote_path/" "$local_path/" --exclude-from="$exclude_from" || fail

      local message="📦 $(combo_path_get_local "$subdir") ⬅️ 🌎 $(combo_path_get_remote "$subdir")"
      ! has_failed && echo_pass "$message"
      has_failed && echo_fail "$message"
    done
  done
  has_failed && return 1
  return 0
}

function default_reset_files() {
  eval $(get_config_keys_as -a sync_groups files_sync)
  ensure_files_sync_local_directories

  for group in "${sync_groups[@]}"; do
    has_option group && [[ "$(get_option group)" != "$group" ]] && continue

    echo_heading "Resetting \"$group\" files..."
    eval $(get_config_as -a subdirs files_sync.$group)
    for subdir in "${subdirs[@]}"; do
      local local_path=$(combo_path_get_local "$subdir")
      fetched_path=$(path_resolve "$FETCH_FILES_PATH/$group" "$local_path")

      local_path=$(path_resolve "$APP_ROOT" "$local_path")
      [ -d "$local_path" ] || mkdir -p "$local_path" || fail

      local rsync_options="-a"
      has_option v && rsync_options="$rsync_options -v"
      rsync $rsync_options "$fetched_path/" "$local_path/" || fail

      local message="🏠 $(path_unresolve "$APP_ROOT" "$local_path") ⬅️ 📦 $(path_unresolve "$APP_ROOT" "$local_path")"
      ! has_failed && echo_pass "$message"
      has_failed && echo_fail "$message"
    done
  done
  has_failed && return 1
  return 0
}
