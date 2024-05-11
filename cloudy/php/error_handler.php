<?php

/**
 * @file
 * Handle PHP errors by routing to the Cloudy error handling.
 *
 * To see the log output the env var LOGFILE must be set to a writeable path.
 */

function _cloudy_php_error_handler_get_level($error_code) {
  $_cloudy_php_error_handler_levels = [
    E_ERROR => 'emergency',
    E_CORE_ERROR => 'emergency',
    E_COMPILE_ERROR => 'emergency',
    E_PARSE => 'emergency',
    E_USER_ERROR => 'error',
    E_RECOVERABLE_ERROR => 'error',
    E_WARNING => 'warning',
    E_CORE_WARNING => 'warning',
    E_COMPILE_WARNING => 'warning',
    E_USER_WARNING => 'warning',
    E_NOTICE => 'info',
    E_USER_NOTICE => 'info',
    E_STRICT => 'debug',
  ];
  if (!isset($_cloudy_php_error_handler_levels[$error_code])) {
    return 'warning';
  }

  return $_cloudy_php_error_handler_levels[$error_code];
}

function _cloudy_php_error_handler() {
  if (func_num_args() < 1) {
    return;
  }
  $args = func_get_args();
  $args = [
    _cloudy_php_error_handler_get_level($args[0]),
    sprintf('%s\n%s on line %s', $args[1], $args[2], $args[3]),
  ];
  call_user_func_array('write_log', $args);
}

function _cloudy_php_shutdown_handler() {
  $last_error = error_get_last();
  if (!$last_error) {
    return;
  }
  $args = [
    _cloudy_php_error_handler_get_level($last_error['type']),
    $last_error['message'],
  ];
  call_user_func_array('write_log', $args);
}

$logfile = getenv('LOGFILE');
if (!empty($logfile)) {
  error_reporting(E_ALL);
}

set_error_handler('_cloudy_php_error_handler');
register_shutdown_function("_cloudy_php_shutdown_handler");
