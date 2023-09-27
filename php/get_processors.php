<?php

/**
 * @file
 * Echo a BASH array of the processor choices.
 *
 * @see _bootstrap.php for class autoloading.
 */
require_once __DIR__ . '/_bootstrap.php';
$config_dir = $argv[1];

$items = [];
$php_class_filepaths = glob("$config_dir/processors/*.php");
foreach ($php_class_filepaths as $php_class_filepath) {
  $classname = pathinfo($php_class_filepath, PATHINFO_FILENAME);
  if (!class_exists($classname)) {
    // If not in the global, then see if it's namespaced.
    $classname = "AKlump\LiveDevPorter\Processors\\$classname";
  }
  try {
    $ref = new ReflectionClass($classname);
  }
  catch (ReflectionException $e) {
    continue;
  }
  $methods = $ref->getMethods(ReflectionMethod::IS_PUBLIC);
  foreach ($methods as $method) {
    $method = $method->getShortName();
    if ('__construct' === $method) {
      continue;
    }
    $items[] = $ref->getShortName() . '::' . $method;
  }
}

$items = array_merge($items, glob("$config_dir/processors/*.sh"));
$items = array_map(function (string $item) {
  return basename($item);
}, $items);
echo implode(' ', $items);
