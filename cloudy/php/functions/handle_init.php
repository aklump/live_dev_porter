<?php

/**
 * @file Parse and process a Cloudy init file map
 *
 * @see $CLOUDY_INIT_RULES
 */

/** @var array $CLOUDY_FAILURES */
/** @var array $CLOUDY_SUCCESSES */
/** @var integer $CLOUDY_EXIT_STATUS */
/** @var string $CLOUDY_BASEPATH */
/** @var string $CLOUDY_CACHE_DIR */
/** @var string $CLOUDY_COMPOSER_VENDOR */
/** @var string $CLOUDY_CONFIG_JSON */
/** @var string $CLOUDY_CORE_DIR */
/** @var string $CLOUDY_INIT_RULES */
/** @var string $CLOUDY_LOG */
/** @var string $CLOUDY_PACKAGE_CONFIG */
/** @var string $CLOUDY_PACKAGE_CONTROLLER */
/** @var string $CLOUDY_PACKAGE_ID */
/** @var string $CLOUDY_RUNTIME_ENV */
/** @var string $CLOUDY_RUNTIME_UUID */
/** @var string $CLOUDY_START_DIR */

/** @var string $PHP_FILE_RUN_CONTROLLER */

use AKlump\Glob\Glob;
use Symfony\Component\Yaml\Yaml;

/**
 * @param string $file_contents
 *
 * @return array
 */
function parse_rules_file(string $file_contents): array {
  $items = Yaml::parse($file_contents);

  return array_map(function ($duplet) {
    return ['init_resource' => $duplet[0], 'copy_to' => $duplet[1]];
  }, $items['copy_map']);
}

/**
 * Expands paths in a copy map and generates an array of resources to be copied.
 *
 * @param array $copy_map The copy map containing the resources to be expanded.
 * @param string $init_resource_basepath The base path for the init resources.
 *
 * @return array An array of expanded resources to be copied.
 */
function expand_paths(array $copy_map, string $init_resource_basepath): array {
  $result = [];
  foreach ($copy_map as $item) {
    $item['copy_to'] = path_resolve_tokens($item['copy_to']);
    $item['init_resource'] = path_make_absolute($item['init_resource'], $init_resource_basepath);
    $resources = Glob::glob($item['init_resource']);
    foreach ($resources as $single_resource) {
      $type = is_file($single_resource) ? 'file' : 'directory';
      $copy_to = $item['copy_to'];
      if ('file' === $type && is_dir($item['copy_to'])) {
        $copy_to = path_make_absolute(basename($single_resource), $item['copy_to']);
      }
      $result[] = [
        'type' => $type,
        'init_resource' => $single_resource,
        'copy_to' => $copy_to,
      ];
    }
  }

  return $result;
}

$path_to_init_rules = $argv[1] ?? '';
if (!$path_to_init_rules || !file_exists($path_to_init_rules)) {
  fail_because('init rules file is empty or missing.');

  return;
}

$copy_map = parse_rules_file(file_get_contents($path_to_init_rules));
$copy_map = expand_paths($copy_map, dirname($CLOUDY_INIT_RULES));

// Check for destination files already existing and exit early.
// Check for globs in second item and exit early.
foreach ($copy_map as $item) {
  if (strstr($item['copy_to'], '*')) {
    fail_because(sprintf('Bad syntax in: %s', path_make_pretty($path_to_init_rules)));
    fail_because(sprintf("Globs not supported for destination paths; invalid: %s", $item['copy_to']));

    return;
  }
  if ('file' === $item['type'] && file_exists($item['copy_to'])) {
    fail_because(sprintf('Copy failed/%s exists: %s', $item['type'], path_make_pretty($item['copy_to'])));

    return;
  }
}

// Now perform the copies.
foreach ($copy_map as $item) {
  if ('file' === $item['type']) {
    $result = copy($item['init_resource'], $item['copy_to']);
    if (FALSE === $result) {
      fail_because(sprintf('File copy failed: %s', $item['init_resource']));
    }
    else {
      echo path_make_pretty($item['copy_to']) . PHP_EOL;
    }
  }
  elseif ('directory' === $item['type']) {
    $output = [];
    # The cp -R command was selected due to its widespread availability and
    # faster execution time for one-time copies. It is a basic command
    # available on all Unix-like systems, performing a simple, local file
    # copy.
    exec(sprintf('cp -R "%s/" "%s/"', $item['init_resource'], $item['copy_to']), $output, $result_code);
    if (0 !== $result_code) {
      fail_because(sprintf('Directory copy failed: %s', $item['init_resource']));
      write_log_error(implode(PHP_EOL, $output));
    }
    else {
      echo path_make_pretty($item['copy_to']) . PHP_EOL;
    }
  }
}
