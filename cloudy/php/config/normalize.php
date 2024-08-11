<?php
/* SPDX-License-Identifier: BSD-3-Clause */

/**
 * @file
 * Load actual configuration file and echo a json string.
 *
 * File arguments:
 *   - path_to_config_schema,
 *   - path_to_master_source_config_file,
 *   - validate[true/false],
 *   - paths_to_additional_config_files separated by "\n"
 *
 * This is the first step in the configuration compiling.
 *
 * @group configuration
 * @see config/cache.php
 */

use JsonSchema\Constraints\Constraint;
use JsonSchema\Validator;

$path_to_config_schema = $argv[1];
$CLOUDY_PACKAGE_CONFIG = $argv[2];
$skip_config_validation = isset($argv[3]) && $argv[3] === 'true';
$additional_config_paths = array_filter(explode("\n", (isset($argv[4]) ? $argv[4] : '')));

$config = [
  '__cloudy' => [
    'CLOUDY_CORE_DIR' => getenv('CLOUDY_CORE_DIR'),
    'CLOUDY_CACHE_DIR' => getenv('CLOUDY_CACHE_DIR'),
    'CLOUDY_PACKAGE_CONTROLLER' => getenv('SCRIPT'),
    'CLOUDY_PACKAGE_CONFIG' => $CLOUDY_PACKAGE_CONFIG,
    'CLOUDY_BASEPATH' => CLOUDY_BASEPATH,

    'CLOUDY_NAME' => getenv('CLOUDY_NAME'),
    'WDIR' => getenv('WDIR'),
    'CLOUDY_LOG' => getenv('CLOUDY_LOG'),
  ],
];
$config = _cloudy_merge_config($config, _cloudy_load_configuration_data($CLOUDY_PACKAGE_CONFIG));

if (empty($config['config_path_base'])) {
  $config['config_path_base'] = CLOUDY_BASEPATH;
}
else {
  // Assume config_path_base, a relative path, was defined in the master config
  // file and make it absolute relative to that file.
  $config['config_path_base'] = path_make_absolute($config['config_path_base'], dirname($CLOUDY_PACKAGE_CONFIG));
}

$_additional_config = [];
foreach ($config['additional_config'] as &$path_or_glob) {
  $path_or_glob = _cloudy_resolve_path_tokens($path_or_glob);
  if (!path_is_absolute($path_or_glob)) {
    $path_or_glob = path_make_absolute($path_or_glob, $config['config_path_base']);
  }
  $paths = _cloudy_resolve_path_globs($path_or_glob);
  $_additional_config = array_merge($_additional_config, $paths);
}
unset($path_or_glob);
$config['additional_config'] = array_values(array_unique(array_filter($_additional_config)));
unset($_additional_config);
$additional_config_paths = array_merge($config['additional_config'], $additional_config_paths);

foreach ($additional_config_paths as $_path) {
  $new_data = _cloudy_load_configuration_data($_path, FALSE);
  if ($new_data) {
    $config = _cloudy_merge_config($config, $new_data);
  }
}
unset($_path);

// Validate against cloudy_config.schema.json.
$validator = new Validator();
$validate_data = json_decode(json_encode($config));
try {
  if (!($schema = json_decode(file_get_contents($path_to_config_schema)))) {
    throw new RuntimeException("Invalid JSON in $path_to_config_schema");
  }
  if (!$skip_config_validation) {
    $validator->validate($validate_data, $schema, Constraint::CHECK_MODE_EXCEPTIONS);
  }
}
catch (Exception $exception) {
  $class = get_class($exception);
  throw new $class("Configuration syntax error in \"" . basename($CLOUDY_PACKAGE_CONFIG) . '": ' . $exception->getMessage());
}

$last_error = error_get_last();
if (!empty($last_error)) {
  // If there are any errors then we have to exit with 1 so that the JSON will
  // not be printed to the cache file; otherwise the cache breaks the cloudy
  // will not be able to load next run due to error messages in the cached.sh
  // file.
  exit(1);
}
echo json_encode($config, JSON_UNESCAPED_SLASHES);
