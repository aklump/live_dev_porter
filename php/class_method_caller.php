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

$method_args = $argv;
array_shift($method_args);
$callback = array_shift($method_args);
$query_string = array_shift($method_args);

$config = [];
parse_str($query_string, $config);
try {
  list($class, $method) = explode('::', $callback);
  if (!class_exists($class)
    && isset($config['autoload'])
    && ($basename = $config['autoload'] . '/' . ltrim($class, '\\') . '.php')
    && file_exists($basename)) {
    require_once $basename;
  }
  $cloudy_config = json_decode(getenv('CLOUDY_CONFIG_JSON'), TRUE) ?? [];
  $method_reflection = new ReflectionMethod($callback);
  if ($method_reflection->isStatic()) {
    $method_args[] = $config;
    $method_args[] = $cloudy_config;
    $result = call_user_func_array($callback, $method_args);
  }
  else {
    $instance = new $class($config, $cloudy_config);
    $result = call_user_func_array([$instance, $method], $method_args);
  }
  echo $result;
  exit(0);
}
catch (\Exception $exception) {
  echo $exception->getMessage();
  exit(max($exception->getCode(), 1));
}

