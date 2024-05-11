<?php

/**
 * @file
 * Provide PHP public functions to be used by cloudy developers.  Functions in
 * this class should be considered stable.
 */

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
    throw new \RuntimeException("Unable to parse invalid YAML string.");
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
    throw new \RuntimeException('Invalid JSON string: ' . json_last_error_msg());
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
    throw new \RuntimeException("Missing JSON file: " . $path);
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
    throw new \RuntimeException('Invalid JSON string: ' . json_last_error_msg());
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

function write_log_exception(\Exception $e, string $level = 'error') {
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
