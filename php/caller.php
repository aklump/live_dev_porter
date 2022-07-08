<?php

/**
 * @file
 *
 * PHP Controller file to allow bash to call class methods.
 *
 * 1. The first argument is expected to be a callable.
 * 1. Additional arguments will be sent to the callable.
 * 1. On error, the method must throw an exception.
 * 1. If successful, a string, if returned, will be passed to Cloudy's succeed_because() function.
 * 1. This will echo a string with the first byte a 0 or 1 which is the exit status.
 *
 * @code
 * $CLOUDY_PHP "$ROOT/php/caller.sh"  "\AKlump\LiveDevPorter\Config\SchemaBuilder::build" "arg1" "arg2"
 * @endcode
 */

require_once __DIR__ . '/../vendor/autoload.php';
$callback_args = $argv;
array_shift($callback_args);
parse_str(array_shift($callback_args), $query);
$callback = array_shift($callback_args);
try {
  list($class, $method) = explode('::', $callback);
  $config = json_decode(getenv('CLOUDY_CONFIG_JSON'), TRUE) ?? [];
  $config += $query;
  $instance = new $class($config);
  $result = call_user_func_array([$instance, $method], $callback_args);
}
catch (\Exception $exception) {
  echo '1' . $exception->getMessage();
  exit(1);
}
echo "0$result";
exit(0);

