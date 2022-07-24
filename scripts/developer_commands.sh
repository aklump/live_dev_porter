#!/usr/bin/env bash

# This happens before we set any of our variables, why?  So that the developer
# can set the variables on the CLI and they will be passed to the processor as
# expected.  This path is for developing processors.
if [[ "$(get_command)" == 'process' ]]; then

  # Load the test vars.
  has_option 'env' && source $(get_option 'env')
  [[ "$LOCAL_ENV_ID" ]] && validate_environment "$LOCAL_ENV_ID" > /dev/null
  [[ "$REMOTE_ENV_ID" ]] && validate_environment "$REMOTE_ENV_ID" > /dev/null
  [[ "$WORKFLOW_ID" ]] && validate_workflow "$WORKFLOW_ID" > /dev/null

  processor_path="$CONFIG_DIR/processors/$(get_command_arg 0)"
  processor="$(path_unresolve "$APP_ROOT" "$processor_path")"

  echo_title "Processor Test"

  if [[ "$(path_extension "$processor_path")" == "sh" ]]; then
    [[ ! -f "$processor_path" ]] && fail_because "Missing file processor: $processor"  && exit_with_failure
    [[ "$JSON_RESPONSE" != true ]] && echo_task "$(path_unresolve "$CONFIG_DIR" "$processor_path")"
    processor_output=$(cd $APP_ROOT; source "$SOURCE_DIR/processor_support.sh"; . "$processor_path")
    processor_result=$?
  else
    php_query="autoload=$CONFIG_DIR/processors/&COMMAND=$COMMAND&LOCAL_ENV_ID=$LOCAL_ENV_ID&REMOTE_ENV_ID=$REMOTE_ENV_ID&DATABASE_ID=$DATABASE_ID&DATABASE_NAME=$DATABASE_NAME&FILES_GROUP_ID=$FILES_GROUP_ID&FILEPATH=$FILEPATH&SHORTPATH=$SHORTPATH&IS_WRITEABLE_ENVIRONMENT=$IS_WRITEABLE_ENVIRONMENT"
    [[ "$JSON_RESPONSE" != true ]] && echo_task "$(path_unresolve "$CONFIG_DIR" "$processor_path")"
    processor_output=$(cd $APP_ROOT; export CLOUDY_CONFIG_JSON; $CLOUDY_PHP "$ROOT/php/class_method_caller.php" "$basename" "$php_query")
    processor_result=$?
  fi
  [[ $processor_result -eq 0 ]] && echo_task_completed && succeed_because "$processor_output" && exit_with_success_elapsed
  echo_task_failed && fail_because "$processor_output" && exit_with_failure
fi
