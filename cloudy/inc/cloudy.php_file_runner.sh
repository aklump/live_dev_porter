#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

# @file
#
# Responsible for running PHP files inside of a Cloudy environment.
#
# @param string The path to the PHP file to run
# @param... additional params will be passed on to the PHP file
#

[[ $# -gt 0 ]] && path_to_php_file="$1"
[[ $# -lt 1 ]] && unset path_to_php_file

if [[ ! "$path_to_php_file" ]]; then
  exit_with_failure "\$path_to_php_file cannot be empty." --status=126
fi
if ! [ -f "$path_to_php_file" ]; then
  fail_because "$path_to_php_file not found and cannot be required." --status=125
  exit_with_failure "Missing PHP file." --status=125
fi

if ! grep -q "^<?" <(head -n 1 "$path_to_php_file"); then
  fail_because "php_file_runner files must begin with <?"
  fail_because "in $path_to_php_file"
  exit_with_failure "Invalid PHP file." --status=124
fi

# This will give the PHP file a little more context when trying to troubleshoot.
PHP_FILE_RUN_CONTROLLER="${BASH_SOURCE[1]}"

# In order to evaluate what exit status this script should use, we are going to
# look to see if CLOUDY_EXIT_STATUS is altered by the PHP file.  If it is then
# we are going to use that altered value.  Otherwise we'll claim success (0).
# We have to stash the current value, which be a failure already, so it can be
# restored later if the PHP does not fail.
_cloudy_exit_status_stashed=$CLOUDY_EXIT_STATUS

# Assume a starting success with the php script.
_php_file_exit_status=0
CLOUDY_EXIT_STATUS=0
"$CLOUDY_PHP" "$CLOUDY_CORE_DIR/php/functions/php_file_runner.php" "$path_to_php_file" "${@:2}"

# Import any variables that PHP has passed to us via cloudy_putenv().
if [[ "$CLOUDY_RUNTIME_ENV" ]] && [ -f "$CLOUDY_RUNTIME_ENV" ]; then
  write_log_debug "Reading PHP variables from $CLOUDY_RUNTIME_ENV"
  source "$CLOUDY_RUNTIME_ENV"
fi

if [[ $CLOUDY_EXIT_STATUS -eq 0 ]]; then
  # Restore the original value, as the script did not change it.
  CLOUDY_EXIT_STATUS=$_cloudy_exit_status_stashed;
else
  # The PHP script reported a failure, so that code will become the exit status,
  # and it will remain the current value of $CLOUDY_EXIT_STATUS.
  _php_file_exit_status=$CLOUDY_EXIT_STATUS
fi

if [ $_php_file_exit_status -ne 0 ]; then
  write_log_debug "$(basename "$path_to_php_file") exit status $_php_file_exit_status; (${@:2})"
fi

if [[ "$php_file_runner_must_exit" == TRUE ]]; then
  has_failed && exit_with_failure
  exit_with_success
fi

return $_php_file_exit_status
