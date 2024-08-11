<?php
/* SPDX-License-Identifier: BSD-3-Clause */

##
# @file Unpublished, private functions
#
# Developers should not rely on the functions in this file as they may change
# at any time.
##

use AKlump\Glob\Glob;
use Ckr\Util\ArrayMerger;
use Symfony\Component\Yaml\Yaml;

/**
 * @param string $path
 *
 * @return string
 * @const string $CLOUDY_BASEPATH
 */
function _cloudy_resolve_path_tokens(string $path): string {
  $path_prefix_tokens = [
    '~' => $_SERVER['HOME'] ?? NULL,
    '$CLOUDY_CORE_DIR' => CLOUDY_CORE_DIR,
    '$CLOUDY_BASEPATH' => CLOUDY_BASEPATH,
  ];
  $path_prefix_tokens = array_filter($path_prefix_tokens);
  foreach ($path_prefix_tokens as $token => $replacement) {
    $replacement = rtrim($replacement, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
    $path = preg_replace('#^' . preg_quote($token, '#') . '/?#', $replacement, $path, 1);
  }

  return $path;
}

/**
 * Resolve globs in absolute or relative paths.
 *
 * @param string $path_or_glob
 *
 * @return string[]
 *
 * @see _cloudy_resolve_path_tokens
 */
function _cloudy_resolve_path_globs(string $path_or_glob): array {
  $paths = [$path_or_glob];
  if (strpos($path_or_glob, '*') !== FALSE) {
    $paths = Glob::glob($path_or_glob);
  }

  return $paths;
}

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
  $logfile = getenv('CLOUDY_LOG');
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
function _cloudy_merge_config() {
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
function _cloudy_load_configuration_data($filepath, $exception_if_not_exists = TRUE) {
  $data = [];
  if (!file_exists($filepath)) {
    if ($exception_if_not_exists) {
      throw new RuntimeException("Missing configuration file: " . $filepath);
    }

    return $data;
  }
  $contents = file_get_contents($filepath);
  if (empty($contents)) {
    throw new RuntimeException(sprintf('Empty configuration file: %s', realpath($filepath)));
  }

  $extension = strtolower(pathinfo($filepath, PATHINFO_EXTENSION));
  switch ($extension) {
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

  return $data;
}

/**
 * Create a hash of a string of filenames separated by \n.
 *
 * @return string
 *   The has of filenames.
 */
function _cloudy_get_config_cache_id() {
  $paths = func_get_arg(0);

  return md5(str_replace("\n", ':', $paths));
}
