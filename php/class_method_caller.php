<?php

/**
 * @file
 *
 * PHP Controller file to allow bash to call class methods.
 *
 * Do not access this file directly, instead use one of:
 *
 * @see call_php_class_method
 * @see call_php_class_method_echo_or_fail
 * @see ClassMethodCaller::CLASS_NOT_EXISTS
 *
 * 1. The first argument is expected to be a class::method string, e.g. "Foo::bar"
 * 1. The second argument is a query string e.g., "1=foo&2=bar" or CSV "foo,bar", which will be deserialized as arguments.
 * 1. Any additional arguments will be sent to the method...
 * 1. Arguments may contain PHP constants, as they will be value-replaced, e.g. "foo,bar,\AKlump\LiveDevPorter\Database\GetExportTables::STRUCTURE"
 * 1. The exit code will be 0 if successful.
 * 1. On error, the method must throw an exception.  The exit code will be 1 or the exception code if > 0.
 */

use AKlump\LiveDevPorter\Config\RuntimeConfig;
use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;
use AKlump\LiveDevPorter\Php\ClassMethodCaller;

require_once __DIR__ . '/_bootstrap.php';

$callback = $argv[1] ?? NULL;
$serialized_args = $argv[2] ?? '';
if ('' === $serialized_args && preg_match('/(.+)\((.+)\)/', $callback, $matches)) {
  $callback = $matches[1];
  $serialized_args = $matches[2];
}

function get_cloudy_config(): RuntimeConfigInterface {
  // This is only available because we export it in call_php_class_method() in
  // live_dev_porter.sh
  $config = [];
  $getenv = function ($name) {
    $value = getenv($name);
    if (FALSE === $value) {
      return NULL;
    }

    return $value;
  };
  $config['APP_ROOT'] = $getenv('APP_ROOT');
  $config['CACHE_DIR'] = $getenv('CACHE_DIR');
  $config['CLOUDY_PHP'] = $getenv('CLOUDY_PHP');
  $config['COMPOSER_VENDOR'] = $getenv('COMPOSER_VENDOR');
  $config['PLUGINS_DIR'] = $getenv('PLUGINS_DIR');
  $config['SOURCE_DIR'] = $getenv('SOURCE_DIR');
  $config['TEMP_DIR'] = $getenv('TEMP_DIR');
  $cloudy_config = json_decode($getenv('CLOUDY_CONFIG_JSON'), TRUE) ?? [];
  if ($cloudy_config) {
    $config = array_merge($config, $cloudy_config);
  }

  return new RuntimeConfig($config);
}

try {
  $class_args = ClassMethodCaller::decodeClassArgs($serialized_args);
  $cloudy_config = get_cloudy_config();
  if (!$cloudy_config->all()) {
    throw new \RuntimeException(sprintf('Missing CLOUDY_CONFIG_JSON; did you `export CLOUDY_CONFIG_JSON` before executing %s', __FILE__));
  }
  list($class, $method) = explode('::', "$callback::");
  $method = (string) $method;
  $class_args = ClassMethodCaller::expressConstants($class_args);

  $caller = new ClassMethodCaller($cloudy_config);
  $method_arguments = array_slice($argv, 3);
  $result = $caller($class, $method, $class_args, $method_arguments);

  // TODO This may prove fragile, however it should be a short-term fix so I don't want to overcomplicate things.
  if (is_array($result)) {
    $result = implode(' ', $result);
  }
}
catch (\Exception $exception) {
  $result = $exception->getMessage();
  $code = $exception->getCode() ?: 1;
}
echo trim($result);
exit($code ?? 0);
