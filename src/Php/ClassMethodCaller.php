<?php

namespace AKlump\LiveDevPorter\Php;

use AKlump\LiveDevPorter\Config\RuntimeConfig;

class ClassMethodCaller {

  /**
   * @var \AKlump\LiveDevPorter\Config\RuntimeConfig
   */
  private $config;

  public function __construct(RuntimeConfig $config) {
    $this->config = $config;
  }

  /**
   * @param string $class
   *   The name of the class in which $method exists.
   * @param string $method
   *   This should throw an exception on failure.  Otherwise any return value
   *   will be considered a success.
   * @param array $args
   *   The arguments to be sent to the class/method.  This may be an associative
   *   or an indexed array.
   * @param array $this ->config->all()
   *
   * @return void
   */
  public function __invoke(string $class, string $method, array $args, array $method_arguments) {
    // For various legacy reasons, the routing of config and arguments is
    // different in different situations.  Is the method static? Is the method
    // __invoke(), etc.  This next bit routes things appropriately.
    $method_reflection = new \ReflectionMethod("$class::$method");
    if ($method_reflection->isStatic()) {
      // Static methods do not receive any configuration.
      $result = call_user_func_array([$class, $method], $method_arguments);
    }
    elseif ('__invoke' === $method) {
      $instance = new $class($this->config);
      $result = call_user_func_array([
        $instance,
        $method,
      ], array_merge($args, $method_arguments));
    }
    else {
      $args[] = $this->config;
      $result = (new $class(...$args))->$method($method_arguments);
    }

    return $result;
  }

  /**
   * @param string $serialized
   *
   * @return array
   *   If serialized results in an associate array, then this will be wrapped in
   *   a single array of one element, like a configuration set.  If this is
   *   indexed, then the array will not be wrapped.  In the case of the latter,
   *   numbers will be typecast to float or int as appropriate.
   *
   * @see self::typecastClassArgs()
   */
  public static function decodeClassArgs(string $serialized): array {
    $config = [];
    if (preg_match('/[&=]/', $serialized)) {
      parse_str($serialized, $config);
    }
    else {
      $config = array_map('trim', explode(',', $serialized));
    }

    // Determine if we have an indexed array, that needs be typecase.
    if (array_keys($config) === array_keys(array_values($config))) {
      return self::typecastClassArgs($config);
    }

    // This is an associative array, so we'll treat it as a single argument,
    // options-like argument.
    return [$config];
  }

  private static function typecastClassArgs(array $args): array {
    // Try to typecast to be compliant with PHP method type-hinting.  If this
    // doesn't work then maybe we can use reflection?
    return array_map(function ($value) {
      if (is_numeric($value)) {
        if ($value == (int) $value) {
          return (int) $value;
        }

        return (float) $value;
      }

      return $value;
    }, $args);
  }

  public static function expressConstants(array $args) {
    return array_map(function ($arg) {
      if (is_string($arg) && defined($arg)) {
        return constant($arg);
      }

      return $arg;
    }, $args);
  }

}
