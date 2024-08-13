<?php

namespace AKlump\LiveDevPorter\Config;

use Symfony\Component\Yaml\Yaml;

class Config {

  public function __construct(array $config) {
    $this->filepath = $config['filepath'];
    $this->name = $config['name'];
    $this->value = $config['value'] ?? NULL;
  }

  /**
   * Set the value of a configuration variable.
   *
   * @return void
   */
  public function set() {
    $data = Yaml::parseFile($this->filepath);
    $data[$this->name] = $this->value;
    if (!file_put_contents($this->filepath, Yaml::dump($data, 2, 6))) {
      throw new \RuntimeException(sprintf('Failed to write new value (%s) for %s in %s', $this->value, $this->name, $this->filepath));
    }
  }

  /**
   * Set the value of a configuration variable.
   *
   * @return void
   */
  public function get() {
    $data = Yaml::parseFile($this->filepath);
    echo sprintf('The value of %s is "%s".', $this->name, $data[$this->name] ?? NULL);
  }
}
