#!/usr/bin/env bash

# @file
#
# Default plugin handler
#

# Check if a remote path exists
#
# $1 - The path on the remote server; relative will be resolved to remote base_path.
#
# Returns 0 if exist; 1 if not.
function _test_remote_path() {
  local remote_path="$1"

  remote_path=$(environment_path_resolve "$REMOTE_ENV_ID" "$remote_path") || return 1
  remote_ssh [ -e "$remote_path" ] &> /dev/null && return 0
  return 1
}

function default_on_configtest() {
  local assert

  [[ "$REMOTE_ENV_ID" == null ]] && return 255
  local directory_path
  # Test remote connection
  echo_task "Able to connect to $REMOTE_ENV_ID server."
  local did_connect=false
  # @link https://unix.stackexchange.com/a/264477
  remote_ssh pwd &> /dev/null && did_connect=true
  if [[ false == "$did_connect" ]]; then
    echo_task_failed
    fail_because "Check $REMOTE_ENV_ID host and user config."
  else
    echo_task_complete
  fi

  # Test remote base_path
  echo_task "$(string_ucfirst "$REMOTE_ENV_ID") base path exists."
  local exists=false
  if _test_remote_path; then
    echo_task_complete
  else
    echo_task_failed
    fail_because "Check \"$remote_base_path\" on $REMOTE_ENV_ID."
  fi

  # Test for file sync groups.
  for environment_id in "${ENVIRONMENT_IDS[@]}"; do
    eval $(get_config_keys_as group_ids "environments.$environment_id.files")
    for group_id in "${group_ids[@]}"; do
      eval $(get_config_as -a file_group_directories "environments.$environment_id.files.$group_id")
      for file_group_directory in "${file_group_directories[@]}"; do

        # Create a nice message
#        assert="$(string_ucfirst "$environment_id"), files group: $group_id directory exists: $file_group_directory"

        # Create local directories if they don't exist to prevent failure.
        file_group_path="$(environment_path_resolve "$environment_id" "$file_group_directory")"
        echo_task "$(string_ucfirst $environment_id) file group $group_id exists: $file_group_path"
        if [[ "$environment_id" == "$LOCAL_ENV_ID" ]]; then
          if [[ -e "$file_group_path" ]] || mkdir -p "$file_group_path"; then
            echo_task_complete
          else
            echo_task_failed
            fail
          fi
        elif [[ "$environment_id" == "$REMOTE_ENV_ID" ]] && _test_remote_path "$file_group_directory"; then
          echo_task_complete
        else
          echo_task_failed
          fail
        fi
      done
    done
  done
}

function default_on_remote_shell() {
  # @link https://stackoverflow.com/a/14703291/3177610
  # @link https://www.man7.org/linux/man-pages/man1/ssh.1.html
  # @link https://github.com/fraction/sshcd/blob/master/sshcd
  local remote_base_path="$(environment_path_resolve $REMOTE_ENV_ID)"
  remote_ssh "(cd $remote_base_path; exec \$SHELL -l)"
}

function default_on_pull_files() {
  local source
  local destination
  local include_from
  local exclude_from
  local source_base
  local destination_base

  # @link https://linux.die.net/man/1/rsync
  local base_rsync_options="-az --copy-unsafe-links --size-only --delete"
  has_option v && base_rsync_options="$base_rsync_options --progress"
  if has_option "dry-run"; then
    echo_yellow_highlight "This is only a preview.  Remove --dry-run to copy files."
    base_rsync_options="$base_rsync_options --dry-run -v"
  fi

  source_base=$(environment_path_resolve "$REMOTE_ENV_ID")
  destination_base=$(environment_path_resolve "$LOCAL_ENV_ID")

  local group_filter=$(get_option group)
  eval $(get_config_keys_as group_ids "environments.$LOCAL_ENV_ID.files")
  if [[ "$group_filter" ]]; then
    array_has_value__array=("${group_ids[@]}")
    array_has_value "$group_filter" || fail_because "The environment \"$LOCAL_ENV_ID\" has not assigned a path to the file group \"$group_filter\"."
  fi

  has_failed && return 1

  for FILES_GROUP_ID in ${group_ids[@]} ; do
    has_option group && [[ "$group_filter" != "$FILES_GROUP_ID" ]] && continue

    eval $(get_config_as source "environments.$REMOTE_ENV_ID.files.$FILES_GROUP_ID")
    if [[ "$group_filter" ]] && [[ ! "$source" ]]; then

      # If there is no source path, it's only considered an error if the user is
      # asking for it via --group; otherwise we will silently skip it.
      fail_because "The environment \"$REMOTE_ENV_ID\" has not assigned a path to the file group \"$group_filter\"." && return 1
    fi

    eval $(get_config_as destination "environments.$LOCAL_ENV_ID.files.$FILES_GROUP_ID")

    if [[ "$source" ]] && [[ "$destination" ]]; then
      rsync_options="$base_rsync_options"
      source_path=$(path_resolve "$source_base" "$source")
      destination_path=$(path_resolve "$destination_base" "$destination")
      ruleset="$CACHE_DIR/rsync_ruleset.$FILES_GROUP_ID.txt"
      if [[ -f "$ruleset" ]]; then
        # I picked --include-from and not --exclude-from, but that is arbitrary.
        # Given my choice, there is no need for us to use --exclude-from because
        # our rulesets are compiled using the +/- prefixes which controls take
        # over such control. It's confusing, see this link:
        # https://stackoverflow.com/q/60584163/3177610
        rsync_options="$rsync_options --include-from="$ruleset""
      fi
      sandbox_directory "$destination_path"
      if [[ ! -d "$destination_path" ]]; then
        mkdir -p "$destination_path" || fail_because "Could not create directory: $destination_path"
      fi
      has_failed && return 1

      has_option v && echo "$rsync_options"
      write_log "rsync $rsync_options "$REMOTE_ENV_AUTH:$source_path/" "$destination_path/""
      echo_task "Save "$FILES_GROUP_ID" to: $destination"
      rsync $rsync_options "$REMOTE_ENV_AUTH:$source_path/" "$destination_path/" || fail

      if has_failed; then
        echo_task_failed
      else
        ! has_option "dry-run" && echo_task_complete

        if [[ "$WORKFLOW_ID" ]]; then
          ENVIRONMENT_ID="$LOCAL_ENV_ID"
          DATABASE_ID=""
          eval $(get_config_as -a includes "file_groups.$FILES_GROUP_ID.include")
          for include in "${includes[@]}"; do
            for FILEPATH in "$destination_path"/${include#/}; do
              if [[ -f "$FILEPATH" ]]; then
                SHORTPATH=$(path_unresolve "$destination_path" "$FILEPATH")
                SHORTPATH=${SHORTPATH#/}
                execute_workflow_processors "$WORKFLOW_ID" || fail
              fi
             done
          done
          has_failed && return 1
        fi
      fi
    fi
  done
  has_failed && return 1
  return 0
}
