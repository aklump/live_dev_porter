#!/usr/bin/env bash

# @file
#
# Default plugin handler
#

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

  # Create the base directories and exclude from stubs.
  eval $(get_config_keys_as -a sync_groups files_sync)
  for group in "${sync_groups[@]}"; do
    _ensure_sync_group_files "$group"
  done
}

function _ensure_sync_group_files() {
  local group="$1"

  [ -d "$PULL_FILES_PATH/$group" ] || mkdir -p "$PULL_FILES_PATH/$group"
  touch "$PULL_FILES_PATH/$group.ignore.txt"
}

function default_fetch_files() {
  eval $(get_config_as remote_app_root "environments.$REMOTE_ENV_ID.app_root")

  # @link https://linux.die.net/man/1/rsync
  local rsync_options="-az --copy-unsafe-links --size-only"
  has_option v && rsync_options="$rsync_options --progress"

  eval $(get_config_keys_as -a sync_groups files_sync)
  for group in "${sync_groups[@]}"; do
    _ensure_sync_group_files "$group"
    echo_heading "Group \"$(string_ucfirst "$group")\""
    eval $(get_config_as -a subdirs files_sync.$group)
    [ -d "$PULL_FILES_PATH/$group" ] || mkdir -p "$PULL_FILES_PATH/$group"
    for subdir in "${subdirs[@]}"; do
      local remote_path=$(path_resolve "$remote_app_root" "$subdir")
      local local_path=$(path_resolve "$PULL_FILES_PATH/$group" "$subdir")
      [ -d "$local_path" ] || mkdir -p "$local_path"
      local exclude_from="$PULL_FILES_PATH/$group.ignore.txt"
      rsync $rsync_options "$(get_remote):$remote_path/" "$local_path/" --exclude-from="$exclude_from" || fail
      ! has_failed && echo_pass $subdir
      has_failed && echo_fail $subdir
    done
  done
  has_failed && return 1
  return 0
}

