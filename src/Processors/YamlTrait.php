<?php

namespace AKlump\LiveDevPorter\Processors;

use Jasny\DotKey;
use Symfony\Component\Yaml\Yaml;

/**
 * To be used to sanitize .env files.
 */
trait YamlTrait {

  /**
   * Replace the the secret value of an assignment with a placeholder
   *
   * @code
   * # Before
   * foo: PGgWcC054cNoZCCkp1KTO2It
   * # After
   * foo: ""
   * @endcode
   *
   * @param string $variable_name
   *   The name to search for.
   * @param string $replace_with
   *   The value to replace with.
   */
  protected function yamlReplaceValue(string $variable_name, string $replace_with = '') {
    $this->validateFileIsLoaded();
    $data = Yaml::parse($this->loadedFile['contents']);
    $data = DotKey::on($data)->set($variable_name, $replace_with);
    $this->loadedFile['contents'] = Yaml::dump($data, 2, 6);
  }

}
