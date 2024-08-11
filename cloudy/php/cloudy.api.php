<?php
/* SPDX-License-Identifier: BSD-3-Clause */

/**
 * @file
 * Provide PHP public functions to be used by cloudy developers.  Functions in
 * this class should be considered stable.
 */

use AKlump\Cloudy\EnvVars;
use Symfony\Component\Yaml\Yaml;
use Jasny\DotKey;

/**
 * Convert a YAML string to a JSON string.
 *
 * @return string
 *   The valid YAML string.
 *
 * @throws \RuntimeException
 *   If the YAML cannot be parsed.
 */
function yaml_to_json($yaml) {
  if (empty($yaml)) {
    return '{}';
  }
  elseif (!($data = Yaml::parse($yaml))) {
    throw new RuntimeException("Unable to parse invalid YAML string.");
  }

  return json_encode($data);
}

/**
 * Get a value from a JSON string.
 *
 * @param string $path
 *   The dot path of the data to get.
 * @param string $json
 *   A valid JSON string.
 *
 * @return mixed
 *   The value at $path.
 */
function json_get_value($path, $json) {
  $subject = json_decode($json);
  if (json_last_error() !== JSON_ERROR_NONE) {
    throw new RuntimeException('Invalid JSON string: ' . json_last_error_msg());
  }

  return DotKey::on($subject)->get($path);
}

/**
 * Loads a JSON file to be used with json_get.
 *
 * Always use this function instead of $(cat foo.json) as json validation and
 * escaping is handled for you.
 *
 * @param string $path
 *
 * @return string
 *   The compressed JSON if file is valid, with single quotes escaped.
 * @throws \InvalidArgumentException If the file does not exist or the file is invalid.
 */
function json_load_file(string $path): string {
  if (!file_exists($path)) {
    throw new RuntimeException("Missing JSON file: " . $path);
  }
  $contents = file_get_contents($path);

  return json_bash_filter($contents);
}

/**
 * Escape a JSON string for special BASH use Cloudy.
 *
 * @param string $json
 *   A JSON string to be used by cloudy.
 *
 * @return string
 *   The compressed and escaped as appropriate JSON string.
 */
function json_bash_filter(string $json): string {
  $data = json_decode($json);
  if (json_last_error() !== JSON_ERROR_NONE) {
    throw new RuntimeException('Invalid JSON string: ' . json_last_error_msg());
  }

  return json_encode($data, JSON_UNESCAPED_SLASHES);
}

##
# @link https://www.php-fig.org/psr/psr-3/
#
function write_log_emergency() {
  $args = func_get_args();
  array_unshift($args, 'emergency');
  call_user_func_array('_cloudy_write_log', $args);
}

##
# You may include 1 or two arguments; when 2, the first is a log label
#
function write_log() {
  $args = func_get_args();
  if (func_num_args() === 1) {
    array_unshift($args, 'log');
  }

  call_user_func_array('_cloudy_write_log', $args);
}

# Writes a log message using the alert level.
#
# $@ - Any number of strings to write to the log.
#
# Returns 0 on success or 1 if the log cannot be written to.
function write_log_alert() {
  $args = func_get_args();
  array_unshift($args, 'alert');
  call_user_func_array('_cloudy_write_log', $args);
}

# Write to the log with level critical.
#
# $1 - The message to write.
#
# Returns 0 on success.
function write_log_critical() {
  $args = func_get_args();
  array_unshift($args, 'critical');
  call_user_func_array('_cloudy_write_log', $args);
}

# Write to the log with level error.
#
# $1 - The message to write.
#
# Returns 0 on success.
function write_log_error() {
  $args = func_get_args();
  array_unshift($args, 'error');
  call_user_func_array('_cloudy_write_log', $args);
}

function write_log_exception(Throwable $e, string $level = 'error') {
  $message = $e->getMessage() . PHP_EOL . $e->getTraceAsString();
  write_log($level, sprintf('%s: %s', $message, $e->getFile()));
}

# Write to the log with level warning.
#
# $1 - The message to write.
#
# Returns 0 on success.
function write_log_warning() {
  $args = func_get_args();
  array_unshift($args, 'warning');
  call_user_func_array('_cloudy_write_log', $args);
}

##
# Log states that should only be thus during development or debugging.
#
# Adds a "... in dev only message to your warning"
#
function write_log_dev_warning() {
  $args = func_get_args();
  array_unshift($args, 'error');
  $args[] = 'This should only be the case for development/debugging.';
  call_user_func_array('_cloudy_write_log', $args);
}

# Write to the log with level notice.
#
# $1 - The message to write.
#
# Returns 0 on success.
function write_log_notice() {
  $args = func_get_args();
  array_unshift($args, 'notice');
  call_user_func_array('_cloudy_write_log', $args);
}

# Write to the log with level info.
#
# $1 - The message to write.
#
# Returns 0 on success.
function write_log_info() {
  $args = func_get_args();
  array_unshift($args, 'info');
  call_user_func_array('_cloudy_write_log', $args);
}

# Write to the log with level debug.
#
# $1 - The message to write.
#
# Returns 0 on success.
function write_log_debug() {
  $args = func_get_args();
  array_unshift($args, 'debug');
  call_user_func_array('_cloudy_write_log', $args);
}

/**
 * Assigns a variable to the Cloudy environment.
 *
 * The Cloudy environment includes the PHP runtime as well as any BASH script
 * that called the PHP using `$PHP_FILE_RUNNER`.  In this way, this is a super
 * function that does what normally is impossible to do, that is, passing
 * variables from PHP back to SHELL across separate processes.  Arrays are also
 * supported for variable values.
 *
 * @param string $var_name
 * @param mixed $value
 *
 * @return void
 *
 * @global string $CLOUDY_RUNTIME_ENV
 * @see \AKlump\Cloudy\EnvVars
 */
function cloudy_putenv(string $var_name, $value): void {
  global $CLOUDY_RUNTIME_ENV;
  (new EnvVars($CLOUDY_RUNTIME_ENV))->putenv($var_name, $value);
}

/**
 * Sort an array by the length of it's values.
 *
 * @param string ...
 *   Any number of items to be taken as an array.
 *
 * @return array
 *   The sorted array
 */
function array_sort_by_item_length() {
  $stack = func_get_args();
  uasort($stack, function ($a, $b) {
    return strlen($a) - strlen($b);
  });

  return array_values($stack);
}

function succeed_because(string $message, string $default = ''): int {
  global $CLOUDY_SUCCESSES;
  global $CLOUDY_EXIT_STATUS;

  // @see cloudy.api.sh::succeed_because()
  $CLOUDY_EXIT_STATUS = 0;

  if (!$message && !$default) {
    return 0;
  }
  elseif ($message) {
    $CLOUDY_SUCCESSES[] = $message;
  }
  elseif ($default) {
    $CLOUDY_SUCCESSES[] = $default;
  }

  return 0;
}

function fail_because(string $message, string $default = '', int $exit_status = 1): int {
  global $CLOUDY_FAILURES;
  global $CLOUDY_EXIT_STATUS;
  // @see cloudy.api.sh::fail()
  $CLOUDY_EXIT_STATUS = $exit_status;

  if (!$message && !$default) {
    return 0;
  }
  elseif ($message) {
    $CLOUDY_FAILURES[] = $message;
  }
  elseif ($default) {
    $CLOUDY_FAILURES[] = $default;
  }

  return 0;
}

function exit_with_failure(int $status = 1) {
  throw new RuntimeException('', $status);
}

function path_is_absolute(string $path) {
  return substr($path, 0, 1) == '/' || substr($path, 0, 1) == '\\';
}

function path_extension(string $path): string {
  return pathinfo($path, PATHINFO_EXTENSION);
}

function path_filename(string $path): string {
  return pathinfo($path, PATHINFO_FILENAME);
}

function path_filesize(string $path): int {
  return filesize($path);
}

function path_is_yaml(string $path): bool {
  return (bool) preg_match('#\.ya?ml$#i', $path);
}

function path_make_absolute($path, $parent, &$exit_status = NULL) {
  // Check if path is absolute
  if ($path[0] == '/') {
    $exit_status = 1;

    return '';
  }

  // Check if parent is not absolute
  if ($parent[0] != '/') {
    $exit_status = 2;

    return '';
  }

  $exit_status = 0;
  $path = rtrim($parent, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . trim($path, DIRECTORY_SEPARATOR);
  if (file_exists($path)) {
    return (string) realpath($path);
  }
  else {
    return (string) $path;
  }
}

function path_make_relative(string $path, string $parent, &$exit_status = NULL): string {
  $path = rtrim($path, DIRECTORY_SEPARATOR);
  $parent = rtrim($parent, DIRECTORY_SEPARATOR);

  if ($path === $parent) {
    $exit_status = 0;

    return '.';
  }

  $parent .= DIRECTORY_SEPARATOR;
  if (strpos($path, $parent) === FALSE) {
    $exit_status = 1;

    return '';
  }
  $exit_status = 0;
  $path = substr($path, strlen($parent));
  if (file_exists("$parent/$path")) {
    $path = realpath("$parent/$path");
    $path = substr($path, strlen($parent));
  }

  return rtrim($path, DIRECTORY_SEPARATOR);
}

function path_make_pretty(string $path): string {
  $p = path_make_relative($path, getcwd());
  if ($p) {
    $path = $p;
  }
  if (!path_is_absolute($path) && '.' !== $path) {
    $path = "./$path";
  }

  return $path;
}
