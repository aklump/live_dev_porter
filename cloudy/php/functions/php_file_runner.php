<?php
/* SPDX-License-Identifier: BSD-3-Clause */

use AKlump\Cloudy\DeserializeBashArray;

/**
 * @param string $path_to_php_file
 * @param... Additional arguments will be passed to PHP file.
 *
 * @exit This must be ignored.
 *
 * A note about BASH arrays.  It's not possible to `export` a BASH array, so
 * instead, it's string value is exported as ${NAME}__SERIALIZED_ARRAY.  This convention
 * must be followed in order to bubble up BASH arrays correctly.  In other words
 * we detect down below if a variable declaration should be a scalar or an array
 * when calling `cloudy_putenv` by looking if ${NAME}__SERIALIZED_ARRAY exists as an
 * environment variable.  See below for the implementing code.
 */

$path_to_php_file = $argv[1];

//
// Context establishment
//

// These are available in the PHP script but changes will not bubble up to the
// controller.
$read_only_vars = [];

$read_only_vars['CLOUDY_START_DIR'] = getenv('CLOUDY_START_DIR');
$read_only_vars['CLOUDY_COMPOSER_VENDOR'] = getenv('CLOUDY_COMPOSER_VENDOR');
$read_only_vars['CLOUDY_CORE_DIR'] = getenv('CLOUDY_CORE_DIR');
require_once $read_only_vars['CLOUDY_CORE_DIR'] . '/php/bootstrap.php';

$read_only_vars['CLOUDY_CONFIG_JSON'] = getenv('CLOUDY_CONFIG_JSON');
$read_only_vars['CLOUDY_RUNTIME_ENV'] = getenv('CLOUDY_RUNTIME_ENV');
$read_only_vars['CLOUDY_CACHE_DIR'] = getenv('CLOUDY_CACHE_DIR');
$read_only_vars['CLOUDY_PACKAGE_CONTROLLER'] = getenv('CLOUDY_PACKAGE_CONTROLLER');
$read_only_vars['CLOUDY_PACKAGE_CONFIG'] = getenv('CLOUDY_PACKAGE_CONFIG');
$read_only_vars['CLOUDY_BASEPATH'] = getenv('CLOUDY_BASEPATH');
$read_only_vars['CLOUDY_RUNTIME_UUID'] = getenv('CLOUDY_RUNTIME_UUID');
// The path to the script containing the $PHP_FILE_RUNNER declaration.
$read_only_vars['PHP_FILE_RUN_CONTROLLER'] = getenv('PHP_FILE_RUN_CONTROLLER');

$log = getenv('CLOUDY_LOG');
if (!empty($log)) {
  $read_only_vars['CLOUDY_LOG'] = getenv('CLOUDY_LOG');
}

// If any of these variables are changed, the changes will be passed up to the
// controller automatically.
$read_write_vars = [];
$read_write_vars['CLOUDY_FAILURES'] = (new DeserializeBashArray())(getenv('CLOUDY_FAILURES__SERIALIZED_ARRAY'));
$read_write_vars['CLOUDY_SUCCESSES'] = (new DeserializeBashArray())(getenv('CLOUDY_SUCCESSES__SERIALIZED_ARRAY'));
$read_write_vars['CLOUDY_EXIT_STATUS'] = (int) getenv('CLOUDY_EXIT_STATUS');

extract($read_write_vars);
extract($read_only_vars);

try {
  // We want $path_to_php_file to have the perspective that it was called by
  // BASH, so we will remove this file from the argv stack.
  array_shift($argv);

  // TODO How to detect if exit() was used in the file?

  // We do not allow return or exit.  From testing the return values can create
  // an unstable, problematic situation, or at least confusing situation when
  // considering keeping Cloudy BASH and Cloudy PHP as similar as possible.
  // Include files may echo values.  If include files wish to communicate an
  // exit status, their choice is to use fail_because() or exit_with_failure()
  // provided the exit status as a function argument.
  require $path_to_php_file;
  unset($error);
}
catch (Exception $exception) {
  $error = $exception;
}
catch (Throwable $throwable) {
  $error = $throwable;
}

if (isset($error)) {
  write_log_exception($error);
  $message = $error->getMessage();
  if ($message) {
    fail_because($message);
  }
  // If the PHP include file is going to throw an exception, it should set a
  // non-zero \Exception code.  Failure to set an \Exception code, will result
  // in an exit code of 127.
  $code = $error->getCode();
  $CLOUDY_EXIT_STATUS = $code ?: 127;

  // This will tell the caller that it needs to call exit_with_* immediately.
  cloudy_putenv('php_file_runner_must_exit', TRUE);
}

// Write envvar changes to the environment.
foreach (array_keys($read_write_vars) as $varname) {
  if (isset(${$varname}) && ${$varname} !== $read_write_vars[$varname]) {
    $new_value = ${$varname};
    cloudy_putenv($varname, $new_value);
  }
}
