<?php

/**
 * @file
 *
 * PHP Controller file to allow bash to call class methods.
 *
 * 1. The first argument is expected to be a callable.
 * 1. Additional arguments will be sent to the callable.
 *
 * @code
 * $CLOUDY_PHP "$ROOT/php/caller.sh"  "\AKlump\LiveDevPorter\Config\SchemaBuilder::build" "arg1" "arg2"
 * @endcode
 */

require_once __DIR__ . '/../vendor/autoload.php';
$callback_args = $argv;
array_shift($callback_args);
$callback = array_shift($callback_args);
try {
  list($class, $method) = explode('::', $callback);
  $config = json_decode(getenv('CLOUDY_CONFIG_JSON'), TRUE) ?? [];
  $instance = new $class($config);
  $result = call_user_func_array([$instance, $method], $callback_args);
  if (is_string($result)) {
    echo $result;
  }
  exit(0);
}
catch (\Exception $exception) {
  echo $exception->getMessage();
  exit(1);
}

