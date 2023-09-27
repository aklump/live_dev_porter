<?php

/**
 * @file
 * Echo a BASH array of database dump files for importing.
 */

use AKlump\LiveDevPorter\LocalTimezone;

require_once __DIR__ . '/_bootstrap.php';

$directories = $argv;
array_shift($directories);
$file_match = array_shift($directories);

/**
 * @param string $path_to_file
 *   Absolute path to a dump file.
 *
 * @return \DateTimeInterface
 *   A dote object pulled from filename or meta data.
 */
function _get_file_date(string $path_to_file): \DateTimeInterface {
  if (preg_match('/_(\d{8}T\d{4,6})\./', $path_to_file, $matches)) {
    $date = date_create($matches[1]);
  }
  else {
    $date = filemtime($path_to_file);
    $date = date_create_from_format('U', $date);
  }

  return $date->setTimezone(LocalTimezone::get());
}

$filepaths = [];
// Add single glob, only if $file_match is not empty.
$file_match = rtrim("*$file_match", '*');
foreach ($directories as $directory) {
  $filepaths = array_merge($filepaths, glob("$directory/$file_match*.sql*"));
}

$base_path = getcwd();
$base_path = rtrim($base_path, '/') . '/';

$choices = [];
foreach ($filepaths as $filepath) {
  $date = _get_file_date($filepath);
  $date = $date->format('M j, Y H:i');
  $prefix = "$date  ";

  $shortpath = $filepath;
  if (strpos($shortpath, $base_path) === 0) {
    $shortpath = substr($shortpath, strlen($base_path));
  }
  if (strpos($shortpath, '.live_dev_porter/data') === 0) {
    $shortpath = substr($shortpath, strlen('.live_dev_porter/data/'));
  }
  $choices[$filepath] = sprintf('%s ... %s', $prefix, $shortpath);
}

arsort($choices);

echo json_encode([
  'count' => count($choices),
  'labels' => array_values($choices),
  'values' => array_keys($choices),
]);
