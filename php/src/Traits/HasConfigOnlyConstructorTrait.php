<?php

namespace AKlump\LiveDevPorter\Traits;

use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;

trait HasConfigOnlyConstructorTrait {

  /**
   * @var \AKlump\LiveDevPorter\Config\RuntimeConfigInterface
   */
  private $config;

  public function __construct(RuntimeConfigInterface $config) {
    $this->config = $config;
  }

}
