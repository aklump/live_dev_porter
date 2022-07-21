<?php

/**
 * @file
 * Convert Loft Deploy configuration to Live Dev Porter.
 */

use AKlump\LiveDevPorter\Migrators\LoftDeployMigrator;
use Symfony\Component\Yaml\Yaml;

require_once __DIR__ . '/../cloudy/php/bootstrap.php';

/**
 * The path to the loft deploy configuration file.
 *
 * @var string
 */
$loft_deploy_config_dir = $argv[1];
if (!is_dir($loft_deploy_config_dir)
  || !is_file($loft_deploy_config_dir . '/config.yml')
  || basename($loft_deploy_config_dir) !== '.loft_deploy') {
  echo "$loft_deploy_config_dir is not an existing .loft_deploy directory.";
  exit(1);
}

$directory = dirname($loft_deploy_config_dir) . '/.live_dev_porter';
$new_config_filepath = $directory . '/config.yml';
if (file_exists($new_config_filepath)) {
  echo "$new_config_filepath already exists.  Conversion cancelled.";
  exit(1);
}

!file_exists($directory) && mkdir($directory, 0755, TRUE);
echo "Saved $directory";

$initial_config = Yaml::parseFile(__DIR__ . '/../init/config.yml');
$migrator = new LoftDeployMigrator($loft_deploy_config_dir, $initial_config);
$new_config = $migrator->getNewConfig();
$yaml = Yaml::dump($new_config, 6, 2);
file_put_contents("$new_config_filepath", $yaml);

foreach (($new_config['workflows'] ?? []) as $workflow_id => $items) {
  if (!is_dir("$directory/processors/")) {
    mkdir("$directory/processors/", 0755, TRUE);
  }
  foreach ($items as $item) {
    if (isset($item['processor'])) {
      touch("$directory/processors/" . $item['processor']);
    }
  }
}

$new_local_config = $migrator->getNewLocalConfig();
$yaml = Yaml::dump($new_local_config, 6, 2);
file_put_contents("$directory/config.local.yml", $yaml);

