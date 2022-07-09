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

  remote_path=$(path_relative_to_env "$REMOTE_ENV_ID" "$remote_path")
  ssh -o BatchMode=yes "$(echo_env_auth "$REMOTE_ENV_ID")" [ -e "$remote_path" ] &> /dev/null && return 0
  return 1
}

function default_configtest() {

  local assert

  # Test remote connection
  assert="Connect to $REMOTE_ENV_ID server"
  local did_connect=false
  # @link https://unix.stackexchange.com/a/264477
  ssh -o BatchMode=yes "$(echo_env_auth $REMOTE_ENV_ID)" pwd &> /dev/null && did_connect=true
  if [[ false == "$did_connect" ]]; then
    fail_because "Check $REMOTE_ENV_ID host and user config."
    echo_fail "$assert"
  else
    echo_pass "$assert"
  fi

  # Test remote base_path
    assert="$REMOTE_ENV_ID base_path exists"
    local exists=false
    if _test_remote_path; then
      echo_pass "$assert"
    else
      fail_because "Check \"$remote_base_path\" on $REMOTE_ENV_ID."
      echo_fail "$assert"
    fi

  # Test for file sync groups.
  local environments=("$LOCAL_ENV_ID" "$REMOTE_ENV_ID")
  for env_id in "${environments[@]}"; do

    eval $(get_config_keys_as -a groups "environments.$env_id.files")
    for group in "${groups[@]}"; do
      eval $(get_config_as -a group_paths "environments.$env_id.files.$group")
      for path in "${group_paths[@]}"; do

        # Create a nice message
        eval $(get_config_as "env" "environments.$env_id.id")
        assert="$env, $group path exists: $path"

        if [[ "$env_id" == "$LOCAL_ENV_ID" ]] && [ -e $(path_relative_to_env "$LOCAL_ENV_ID" "$path") ]; then
          echo_pass "$assert"
        elif [[ "$env_id" == "$REMOTE_ENV_ID" ]] && _test_remote_path "$path"; then
          echo_pass "$assert"
        else
          echo_fail "$assert" && fail
        fi
      done
    done
  done
}

function default_remote_shell() {
  # @link https://stackoverflow.com/a/14703291/3177610
  # @link https://www.man7.org/linux/man-pages/man1/ssh.1.html
  # @link https://github.com/fraction/sshcd/blob/master/sshcd
  local remote_base_path="$(path_relative_to_env $REMOTE_ENV_ID)"
  ssh -t $(echo_env_auth $REMOTE_ENV_ID) "(cd $remote_base_path; exec \$SHELL -l)"
}

function default_info() {
  eval $(get_config_as remote_app_root "environments.$REMOTE_ENV_ID.base_path")

  echo_key_value "SSH" "$(echo_env_auth $REMOTE_ENV_ID)"
  echo_key_value "$REMOTE_ENV_ID app root" "$remote_app_root"
}

function default_pull_files() {
  local source
  local destination
  local include_from
  local exclude_from

  # @link https://linux.die.net/man/1/rsync
  local base_rsync_options="-az --copy-unsafe-links --size-only --delete"
  has_option v && base_rsync_options="$base_rsync_options --progress"
  if has_option "dry-run"; then
    echo_yellow_highlight "This is only a preview.  Remove --dry-run to copy files."
    base_rsync_options="$base_rsync_options --dry-run -v"
  fi

  eval $(get_config_as source_ssh "environments.${REMOTE_ENV_LOOKUP}.ssh")
  eval $(get_config_as source_base "environments.${REMOTE_ENV_LOOKUP}.base_path")
  eval $(get_config_as destination_base "environments.${LOCAL_ENV_LOOKUP}.base_path")
  if [[ "APP_ROOT" == "$destination_base" ]]; then
    destination_base="$APP_ROOT"
  fi

  local group_filter=$(get_option group)
  eval $(get_config_keys_as -a group_ids "environments.${LOCAL_ENV_LOOKUP}.files")
  if [[ "$group_filter" ]]; then
    array_has_value__array=("${group_ids[@]}")
    array_has_value "$group_filter" || fail_because "The environment \"$LOCAL_ENV_ID\" has not assigned a path to the file group \"$group_filter\"."
  fi

  has_failed && return 1

  for group_id in ${group_ids[@]} ; do
    has_option group && [[ "$group_filter" != "$group_id" ]] && continue

    eval $(get_config_as source "environments.${REMOTE_ENV_LOOKUP}.files.${group_id}")
    if [[ "$group_filter" ]] && [[ ! "$source" ]]; then

      # If there is no source path, it's only considered an error if the user is
      # asking for it via --group; otherwise we will silently skip it.
      fail_because "The environment \"$REMOTE_ENV_ID\" has not assigned a path to the file group \"$group_filter\"." && return 1
    fi

    eval $(get_config_as destination "environments.${LOCAL_ENV_LOOKUP}.files.${group_id}")

    if [[ "$source" ]] && [[ "$destination" ]]; then
      rsync_options="$base_rsync_options"
      source=$(path_resolve "$source_base" "$source")
      destination=$(path_resolve "$destination_base" "$destination")
      ruleset="$CACHE_DIR/rsync_ruleset.$group_id.txt"
      if [[ -f "$ruleset" ]]; then
        # I picked --include-from and not --exclude-from, but that is arbitrary.
        # Given my choice, there is no need for us to use --exclude-from because
        # our rulesets are compiled using the +/- prefixes which controls take
        # over such control. It's confusing, see this link:
        # https://stackoverflow.com/q/60584163/3177610
        rsync_options="$rsync_options --include-from="$ruleset""
      fi

      sandbox_directory "$destination"
      if [[ ! -d "$destination" ]]; then
        mkdir -p "$destination" || fail_because "Could not create directory: $destination"
      fi
      has_failed && return 1

      has_option v && echo "$rsync_options"
      write_log "rsync $rsync_options "$source_ssh:$source/" "$destination/""
      rsync $rsync_options "$source_ssh:$source/" "$destination/" || fail

      if has_failed; then
        echo_fail "Files group \"$group_id\" failed to download."
      else

        # Apply processors to include files.
        eval $(get_config_keys_as -a 'keys' "file_groups")
        for key in "${keys[@]}"; do
          eval $(get_config_as id "file_groups.${key}.id")
          if [[ "$id" == "$group_id" ]]; then

            # Determine if this group has an processors
            eval $(get_config_as -a processors "file_groups.${key}.processors")
            [[ ${#processors[@]} -eq 0 ]] && continue

            eval $(get_config_as -a includes "file_groups.${key}.include")
            for include in "${includes[@]}"; do
              for filepath in "$destination"/$include; do
                if [[ -f "$filepath" ]]; then
                  for processor in "${processors[@]}"; do
                    processor_path="$CONFIG_DIR/processors/$processor"
                    if [[ -f "$processor_path" ]]; then
                      short_path=$(path_unresolve "$destination" "$filepath")
                      short_path=${short_path#/}
                      if [[ "$(path_extension "$processor_path")" == "php" ]]; then
                        processor_output=$($CLOUDY_PHP "$processor_path" "$filepath" "$short_path")
                      else
                        processor_output=$(. "$processor_path" "$filepath" "$short_path")
                      fi
                      if [[ $? -ne 0 ]]; then
                        [[ "$processor_output" ]] && fail_because "$processor_output"
                        fail_because "\"$processor\" has failed while processing: $short_path (in files group \"$group_id\")."
                        return 1
                      fi
                     [[ "$processor_output" ]] && succeed_because "$processor_output"
                    else
                      fail_because "Missing \"$group_id\" files group processor: $processor" && return 1
                    fi
                  done
                fi
               done
            done
          fi
        done

        echo_pass "Files group \"$group_id\" finished."
        has_option "dry-run" || succeed_because "\"$group_id\" saved to $(path_unresolve "$APP_ROOT" "$destination")"
      fi
#      local message="📦 $local_relative_path ⬅️ 🌎 $remote_relative_path"
    fi
  done
  has_failed && return 1
  return 0
}
