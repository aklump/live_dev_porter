<?php

/**
 * Expand a path based on $config_path_base.
 *
 * This function can handle:
 * - paths that begin with ~/
 * - paths that contain the glob character '*'
 * - absolute paths
 * - relative paths to `config_path_base`
 *
 * @param string $path
 *   The path to expand.
 *
 * @return array
 *   The expanded paths.  This will have multiple items when using globbing.
 *
 * @see _cloudy_get_config in cloudy.functions.sh
 */
function _cloudy_realpath($path) {
  global $_config_path_base;

  # Replace ~ with the actual home page
  if (!empty($_SERVER['HOME'])) {
    $path = preg_replace('/^~\//', rtrim($_SERVER['HOME'], '/') . '/', $path);
  }

  # Replace tokens
  if (strstr($path, '{APP_ROOT}')) {
    $app_root = rtrim(APP_ROOT, '/');
    // We support both versions: "{APP_ROOT}foo" and "{APP_ROOT}/foo"
    $path = preg_replace('#{APP_ROOT}/?#', "$app_root/", $path);
  }

  // If $path is not absolute then we need to make it so.
  $path_is_absolute = !(!empty($path) && substr($path, 0, 1) !== '/');
  if (!$path_is_absolute) {
    //    $prefix = rtrim(ROOT, '/') . '/';
    $path = implode('/', array_filter([
      rtrim(APP_ROOT, '/'),
      rtrim($_config_path_base, '/'),
      rtrim($path, '/'),
    ]));
  }
  if (strstr($path, '*')) {
    $paths = glob($path);
  }
  else {
    $paths = [$path];
  }
  $paths = array_map(function ($item) {
    return is_file($item) ? realpath($item) : $item;
  }, $paths);

  return $paths;
}
