#!/usr/bin/env bash

# @file
#
# Default plugin handler
#

# Check if a remote path exists
#
# $1 - The (remote) environment ID.
# $2 - The path on the remote server; relative will be resolved to remote base_path.
#
# Returns 0 if exist; 1 if not.
function _test_remote_path() {
  local environment_id="$1"
  local remote_path="$2"

  remote_path=$(environment_path_resolve "$environment_id" "$remote_path") || return 1
  remote_ssh "$environment_id" [ -e "$remote_path" ] &> /dev/null && return 0
  return 1
}

# Execute mkdir on an environment.
#
# $1 - string Environment ID
# $2 - string The path to pass to mkdir
#
# Returns 0 if .
function default_mkdir() {
  local environment_id="$1"
  local path="$2"

  # Create the remote directory if not already there to receive the dumpfile.
  if is_ssh_connection "$environment_id"; then
    remote_ssh "$environment_id" "mkdir -p \"$path\""  &> /dev/null && return 0
  else
    mkdir -p "$path"  &> /dev/null && return 0
  fi
  return 1
}

function default_on_configtest() {
  local did_connect
  local directory_path
  local exits
  local file_group_path
  local file_group_shortpath
  local heading
  local is_remote
  local command

  # Test for file sync groups.
  for environment_id in "${ACTIVE_ENVIRONMENTS[@]}"; do
    is_remote=''
    if [[ "$LOCAL_ENV_ID" != "$environment_id" ]] && is_ssh_connection "$environment_id"; then
      is_remote=true
    fi
    eval $(get_config_as env_label "environments.$environment_id.label")
    [[ "$is_remote" ]] && heading="Remote" || heading="Local"
    echo
    echo_heading "$heading Environment: $env_label"

    eval $(get_config_as base "environments.$environment_id.base_path")
    echo_task "environments.$environment_id.base_path is absolute"
    if ! path_is_absolute "$base"; then
      echo_task_failed
    else
      echo_task_completed
    fi

    # Test for all CLI tool dependencies.
    tools=('gzip' 'mysqldump' 'mysql')
    for tool in "${tools[@]}"; do
      echo_task "$(string_ucfirst "$environment_id") has \"$tool\" installed."
      command="which $tool"
      if [[ "$is_remote" ]]; then
        remote_ssh "$environment_id" "$command" &> /dev/null
      else
        $command &> /dev/null
      fi
      if [[ $? -gt 0 ]]; then
        echo_task_failed
        fail_because "Is the directory containing $tool found in your \$PATH variable on $environment_id?"
        fail_because "You may be able to correct by setting shell_commands.$tool in config.local.yml on $environment_id?"
      else
        echo_task_completed
      fi
    done

    if [[ "$is_remote" ]]; then
      # Test remote connection
      echo_task "Able to connect to $environment_id server."
      did_connect=false
      # @link https://unix.stackexchange.com/a/264477
      remote_ssh "$environment_id" pwd &> /dev/null && did_connect=true
      if [[ false == "$did_connect" ]]; then
        echo_task_failed
        fail_because "Check $environment_id host and user config."
      else
        echo_task_completed
      fi

      # Test remote base_path
      echo_task "$(string_ucfirst "$environment_id") base path exists."
      exists=false
      if _test_remote_path "$environment_id"; then
        echo_task_completed
      else
        echo_task_failed
        fail_because "Check \"$remote_base_path\" on $environment_id."
      fi

      # Test for ionice on remote server
      echo_task "Assert \"ionice\" is installed on $environment_id."
      if remote_ssh "$environment_id" "which ionice >/dev/null" &> /dev/null; then
        echo_task_completed
      else
        echo_task_failed
        fail_because "ionice is missing and performance of the $environment_id server can be affected during some commands like pull, export, and import."
        fail_because "Learn more at: https://www.tiger-computing.co.uk/linux-tips-nice-and-ionice"
      fi
    fi

    eval $(get_config_keys_as group_ids "environments.$environment_id.files")
    for group_id in "${group_ids[@]}"; do
      eval $(get_config_as -a file_group_directories "environments.$environment_id.files.$group_id")
      for file_group_directory in "${file_group_directories[@]}"; do

        file_group_path="$(environment_path_resolve "$environment_id" "$file_group_directory")"

        # Sometimes the path ends in foo/./
        file_group_shortpath=${file_group_path%/}
        file_group_shortpath=${file_group_shortpath%.}
        file_group_shortpath=${file_group_shortpath%/}

        echo_task "$(string_ucfirst $environment_id) file group \"$group_id\" exists: $file_group_shortpath"

        if [[ "$is_remote" ]]; then
          _test_remote_path "$environment_id" "$file_group_directory" && echo_task_completed || echo_task_failed

        # ... it does not, so it's a local one.
        else
          # Create local directories if they don't exist to prevent failure.
          if [[ -e "$file_group_path" ]] || mkdir -p "$file_group_path"; then
            echo_task_completed
          else
            echo_task_failed
            fail
          fi
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
  # The -l command runs bash as if it was a login shell, which is more likely
  # going to contain the customizations the user is expecting.  Another
  # possibility for $SHELL is mysecureshell which does not have that option.

  if has_option "verbose"; then
    echo "ssh "$(get_ssh_auth "$REMOTE_ENV_ID")""
    echo
  fi

  remote_ssh "$REMOTE_ENV_ID" "(cd $remote_base_path; [[ \$(basename \$SHELL) == bash ]] && exec \$SHELL -l || exec \$SHELL)"
}

function default_on_push_files() {
  local destination
  local destination_base
  local source
  local source_base
  local stat_arguments

  [[ ! "$WORKFLOW_ID" ]] && write_log_debug "Files will only be pushed when there is a workflow." && return 0

  # @link https://linux.die.net/man/1/rsync
  # @link https://stackoverflow.com/a/4114979/3177610 (chmod) File permissions
  # if not properly set on the receiving end will wreak havoc during processing,
  # renaming, etc.  Therefor we ensure the user caen read and write at this
  # point.  It sets up for success.
  local base_rsync_options="-az --copy-unsafe-links --size-only --delete --chmod=u+rw"
  has_option v && base_rsync_options="$base_rsync_options --progress"
  if has_option "dry-run"; then
    echo_yellow_highlight "This is only a preview.  Remove --dry-run to copy files."
    base_rsync_options="$base_rsync_options --dry-run -v"
  fi

  source_base=$(environment_path_resolve "$LOCAL_ENV_ID")
  destination_base=$(environment_path_resolve "$REMOTE_ENV_ID")

  eval $(get_config_as -a group_ids "workflows.$WORKFLOW_ID.file_groups")
  [[ ${#group_ids[@]} -eq 0 ]] && write_log_debug "The workflow \"$WORKFLOW_ID\" has not defined any file_groups; no files pushed." && return 0

  local group_filter=$(get_option group)
  if [[ "$group_filter" ]]; then
    array_has_value__array=("${group_ids[@]}")
    array_has_value "$group_filter" || fail_because "The group filter \"$group_filter\" cannot be used with the workflow \"$WORKFLOW_ID\" because that workflow does not list that group in it's configuration."
  fi

  has_failed && return 1

  for FILES_GROUP_ID in ${group_ids[@]} ; do
    has_option group && [[ "$group_filter" != "$FILES_GROUP_ID" ]] && continue

    eval $(get_config_as source "environments.$LOCAL_ENV_ID.files.$FILES_GROUP_ID")
    if [[ "$group_filter" ]] && [[ ! "$source" ]]; then

      # If there is no source path, it's only considered an error if the user is
      # asking for it via --group; otherwise we will silently skip it.
      fail_because "The environment \"$LOCAL_ENV_ID\" has not assigned a path to the file group \"$group_filter\"." && return 1
    fi

    eval $(get_config_as destination "environments.$REMOTE_ENV_ID.files.$FILES_GROUP_ID")

    if [[ "$source" ]] && [[ "$destination" ]]; then

      stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=push&TYPE=2&ID=$FILES_GROUP_ID&SOURCE=$LOCAL_ENV_ID"
      call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"

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

      ! default_mkdir "$REMOTE_ENV_ID" "$destination_path" && fail_because "Could not create directory: $destination_path"
      has_failed && return 1

      has_option v && echo "$rsync_options"
      write_log "rsync $rsync_options "$source_path/" "${REMOTE_ENV_AUTH}$destination_path/""
      echo_task "Push files group \"$FILES_GROUP_ID\" to: $destination"
      rsync $rsync_options "$source_path/" "${REMOTE_ENV_AUTH}$destination_path/" || fail

      if has_failed; then
        echo_task_failed
      else
        ! has_option "dry-run" && echo_task_completed

        if [[ "$WORKFLOW_ID" ]]; then
          eval $(get_config_as -a processors "workflows.$WORKFLOW_ID.processors")
          if [[ ${#processors[@]} -gt 0 ]]; then
            write_log_notice "Workflow processors are not yet supported for files during the push operation."
          fi
        fi

        call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
      fi
    fi
  done
  has_failed && return 1
  return 0
}

function default_on_pull_files() {
  local destination
  local destination_base
  local source
  local source_base
  local stat_arguments

  [[ ! "$WORKFLOW_ID" ]] && write_log_debug "Files will only be pulled when there is a workflow." && return 0

  # @link https://linux.die.net/man/1/rsync
  # @link https://stackoverflow.com/a/4114979/3177610 (chmod) File permissions
  # if not properly set on the receiving end will wreak havoc during processing,
  # renaming, etc.  Therefor we ensure the user caen read and write at this
  # point.  It sets up for success.
  local base_rsync_options="-az --copy-unsafe-links --size-only --delete --chmod=u+rw"
  has_option v && base_rsync_options="$base_rsync_options --progress"
  if has_option "dry-run"; then
    echo_yellow_highlight "This is only a preview.  Remove --dry-run to copy files."
    base_rsync_options="$base_rsync_options --dry-run -v"
  fi

  source_base=$(environment_path_resolve "$REMOTE_ENV_ID")
  destination_base=$(environment_path_resolve "$LOCAL_ENV_ID")

  eval $(get_config_as -a group_ids "workflows.$WORKFLOW_ID.file_groups")
  [[ ${#group_ids[@]} -eq 0 ]] && write_log_debug "The workflow \"$WORKFLOW_ID\" has not defined any file_groups; no files pulled." && return 0

  local group_filter=$(get_option group)
  if [[ "$group_filter" ]]; then
    array_has_value__array=("${group_ids[@]}")
    array_has_value "$group_filter" || fail_because "The group filter \"$group_filter\" cannot be used with the workflow \"$WORKFLOW_ID\" because that workflow does not list that group in it's configuration."
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

      stat_arguments="CACHE_DIR=$CACHE_DIR&COMMAND=pull&TYPE=2&ID=$FILES_GROUP_ID&SOURCE=$REMOTE_ENV_ID"
      call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::start" "$stat_arguments"

      rsync_options="$base_rsync_options"
      source_path=$(path_resolve "$source_base" "$source")
      destination_path=$(path_resolve "$destination_base" "$destination")

      ruleset="$CACHE_DIR/rsync_ruleset.$FILES_GROUP_ID.txt"
      [[ -f "$ruleset" ]] || fail_because "Missing ruleset $ruleset; try clearing caches." || return 1

      # I picked --include-from and not --exclude-from, but that is arbitrary.
      # Given my choice, there is no need for us to use --exclude-from because
      # our rulesets are compiled using the +/- prefixes which controls take
      # over such control. It's confusing, see this link:
      # https://stackoverflow.com/q/60584163/3177610
      rsync_options="$rsync_options --include-from="$ruleset""
      sandbox_directory "$destination_path"
      if [[ ! -d "$destination_path" ]]; then
        mkdir -p "$destination_path" || fail_because "Could not create directory: $destination_path"
      fi
      has_failed && return 1

      has_option v && echo "$rsync_options"
      write_log "rsync $rsync_options "${REMOTE_ENV_AUTH}$source_path/" "$destination_path/""
      echo_task "Pull files group \"$FILES_GROUP_ID\" to: $destination"
      rsync $rsync_options "${REMOTE_ENV_AUTH}$source_path/" "$destination_path/" || fail

      if has_failed; then
        echo_task_failed
      else
        ! has_option "dry-run" && echo_task_completed

        if [[ "$WORKFLOW_ID" ]]; then
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

        call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Statistics::stop" "$stat_arguments"
      fi
    fi
  done
  has_failed && return 1
  return 0
}
