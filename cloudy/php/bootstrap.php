<?php

/**
 * @file
 * Bootstrap for all php files.
 */

use Ckr\Util\ArrayMerger;
use Symfony\Component\Yaml\Yaml;

/**
 * Root directory of the Cloudy instance script.
 */
define('ROOT', getenv('ROOT'));
if (empty(ROOT)) {
  throw new RuntimeException('Environment var "ROOT" cannot be empty.');
}
define('APP_ROOT', getenv('APP_ROOT'));
if (empty(APP_ROOT)) {
  throw new RuntimeException('Environment var "APP_ROOT" cannot be empty.');
}
$composer_vendor = getenv('COMPOSER_VENDOR');
if (empty($composer_vendor)) {
  throw new RuntimeException('Environment var "$composer_vendor" cannot be empty.');
}

require_once __DIR__ . '/error_handler.php';
require_once __DIR__ . '/cloudy.functions.php';

/** @var \Composer\Autoload\ClassLoader $class_loader */
$class_loader = require_once $composer_vendor . '/autoload.php';

/**
 * Create a log entry if logging is enabled.
 *
 * @param string $level
 *   The log level
 * @param... string $message
 *   Any number of string parameters, each will be a single log line entry.
 *
 * @return void
 */
function _cloudy_write_log($level) {
  $logfile = getenv('LOGFILE');
  if (empty($logfile)) {
    return;
  }
  $args = func_get_args();
  $level = array_shift($args);
  $directory = dirname($logfile);
  if (!is_dir($directory)) {
    mkdir($directory, 0755, TRUE);
  }

  $date = date('D M d H:i:s T Y');
  $lines = array_map(function ($message) use ($level, $date) {
    return "[$date] [$level] $message";
  }, $args);
  $stream = fopen($logfile, 'a');
  fwrite($stream, implode(PHP_EOL, $lines) . PHP_EOL);
  fclose($stream);
}

/**
 * Merge an array of configuration arrays.
 *
 * @param... two or more arrays to merge.
 *
 * @return array|mixed
 *   The merged array.
 */
function _merge_config() {
  $stack = func_get_args();
  $merged = [];
  while (($array = array_shift($stack))) {
    $merged = ArrayMerger::doMerge($merged, $array);
  }

  return $merged;
}

/**
 * Load a configuration file into memory.
 *
 * @param $filepath
 *   The absolute filepath to a configuration file.
 *
 * @return array|mixed
 */
function _load_configuration_data($filepath, $exception_if_not_exists = TRUE) {
  $data = [];
  if (!file_exists($filepath)) {
    if ($exception_if_not_exists) {
      throw new RuntimeException("Missing configuration file: " . $filepath);
    }

    return $data;
  }
  if (!($contents = file_get_contents($filepath))) {
    // TODO Need a php method to write a log file, and then log this.
    //    throw new \RuntimeException("Empty configuration file: " . realpath($filepath));
  }
  if ($contents) {
    switch (($extension = pathinfo($filepath, PATHINFO_EXTENSION))) {
      case 'yml':
      case 'yaml':
        try {
          if ($yaml = Yaml::parse($contents)) {
            $data += $yaml;
          }
        }
        catch (\Exception $exception) {
          write_log_exception($exception);
          $message = sprintf("Syntax error in configuration file: %s: %s", $filepath, $exception->getMessage());
          write_log_error($message);
          $class = get_class($exception);
          throw new $class($message, $exception->getCode());
        }
        break;

      case 'json':
        if ($json = json_decode($contents, TRUE)) {
          $data += $json;
        }
        break;

      default:
        throw new RuntimeException("Configuration files of type \"$extension\" are not supported.");

    }
  }

  return $data;
}

/**
 * Create a hash of a string of filenames separated by \n.
 *
 * @return string
 *   The has of filenames.
 */
function get_config_cache_id() {
  $paths = func_get_arg(0);

  return md5(str_replace("\n", ':', $paths));
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

require_once __DIR__ . '/cloudy.api.php';
