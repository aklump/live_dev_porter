<?php

namespace AKlump\LiveDevPorter\Helpers;

class ResolveClassShortname {

  /**
   * Tries to resolve missing namespace on class shortname.
   *
   * Adds $namespace if necessary to make the class exist.
   *
   * @param string $class
   *   This may take any of these forms: Foo, \Some\Path\Foo, Foo::bar,
   *   \Some\Path\Foo::bar.
   *
   * @return string
   *   If $class doesn't exist, and adding the namespace would locate it, then
   *   such is returned.
   *
   * @throws \RuntimeException If FQN cannot be determined.
   */
  public function __invoke(string $shortname, string $namespace): string {
    list($class, $method) = explode('::', $shortname . '::', 2);
    $namespace = rtrim($namespace, '\\');
    $try = $namespace . '\\' . $class;
    if (class_exists($try)) {
      return $this->normalize("$try::$method");
    }
    if (class_exists($class)) {
      return $this->normalize("$class::$method");
    }
    throw new \RuntimeException(sprintf('Cannot find namespace for class with shortname: %s', $class));
  }

  private function normalize(string $classname): string {
    $classname = ltrim($classname, '\\');

    return '\\' . rtrim("$classname", ':');
  }

}
