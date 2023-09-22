<?php

namespace AKlump\LiveDevPorter\Config;

use Jasny\DotKey;

class RuntimeConfig implements RuntimeConfigInterface {

  protected $config = [];

  public function __construct(array $config) {
    $this->setConfig($config);
  }

  public function setConfig(array $config): self {
    $this->config = $config;

    return $this;
  }

  public function all(): array {
    return $this->config;
  }

  public function get(string $dot_path) {
    return (new DotKey($this->config))->get($dot_path);
  }
}
