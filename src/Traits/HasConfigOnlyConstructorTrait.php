<?php

namespace AKlump\LiveDevPorter\Traits;

use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;

trait HasConfigOnlyConstructorTrait {

  public function __construct(RuntimeConfigInterface $config) {
    $this->config = $config;
  }

}
