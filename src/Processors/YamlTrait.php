<?php

namespace AKlump\LiveDevPorter\Processors;

use Jasny\DotKey;
use Symfony\Component\Yaml\Yaml;

/**
 * To be used to sanitize .env files.
 *
 * @deprecated Since version 0.0.160, Use \AKlump\LiveDevPorter\Processors\RedactPasswords instead.
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
   *
   * @return bool Will be true if the contents of the file have changed due to
   * the method call.  Use to flag if you want to save the file.
   */
  protected function yamlReplaceValue(string $variable_name, string $replace_with = ''): bool {
    $this->validateFileIsLoaded();
    if (empty($this->loadedFile['contents'])) {
      return FALSE;
    }
    $data = Yaml::parse($this->loadedFile['contents']);
    if (DotKey::on($data)->exists($variable_name)) {
      $data = DotKey::on($data)->set($variable_name, $replace_with);
    }

    $serialize = function ($data): string {
      return is_null($data) ? '' : Yaml::dump($data, 6, 2);
    };

    $unchanged = $serialize(Yaml::parse($this->loadedFile['contents']));
    $this->loadedFile['contents'] = $serialize($data);

    return $unchanged !== $this->loadedFile['contents'];
  }

}
