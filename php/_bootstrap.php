<?php

require_once __DIR__ . '/../cloudy/php/bootstrap.php';

/** @var \Composer\Autoload\ClassLoader $class_loader */

// Dynamically create the autoloading for any classes in the processors directory.
$processors_dir = getenv('CLOUDY_BASEPATH') . '/.live_dev_porter/processors/';
if (file_exists($processors_dir) && is_dir($processors_dir)) {
  $class_loader->addPsr4('', [
    $processors_dir,
  ]);
  $class_loader->addPsr4('AKlump\LiveDevPorter\Processors\\', [
    $processors_dir,
  ]);
}
