<?php

/**
 * @file
 *
 * PHP Controller file to allow bash to call class methods.
 *
 * 1. The first argument is expected to be a class::method string
 * 1. If ::method is static it will receive the arguments.
 * 1. If ::method is not static the class constructor will receive the
 * arguments, and the method will be called without arguments.
 * 3. On error, the method must throw an exception.
 * 4. If successful, a string, if returned, will be passed to Cloudy's succeed_because() function.
 */

require_once __DIR__ . '/../cloudy/php/bootstrap.php';

$callback = $argv[1];
$query_string = $argv[2];

$config = [];
parse_str($query_string, $config);
try {
  list($class, $method) = explode('::', $callback);
  if (!class_exists($class) && isset($config['autoload']) && file_exists($config['autoload'] . "/$class.php")) {
    require_once $config['autoload'] . "/$class.php";
  }
  $cloudy_config = json_decode(getenv('CLOUDY_CONFIG_JSON'), TRUE) ?? [];
  $method_reflection = new ReflectionMethod($callback);
  if ($method_reflection->isStatic()) {
    $result = call_user_func_array($callback, [$config, $cloudy_config]);
  }
  else {
    $instance = new $class($config, $cloudy_config);
    $result = call_user_func_array([$instance, $method], []);
  }
  echo $result;
  exit(0);
}
catch (\Exception $exception) {
  echo $exception->getMessage();
  exit(1);
}

