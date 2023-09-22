<?php

namespace AKlump\LiveDevPorter\Traits;


use AKlump\LiveDevPorter\Helpers\CallPlugin;

trait CanCallPluginsTrait {

  /**
   * Call a plugin by name.
   *
   * @param string $name
   * @param... Additional will be sent to plugin.
   *
   * @return mixed
   */
  public function callPlugin(string $name) {
    $args = func_get_args();

    return (new CallPlugin($this->config))(...$args);
  }
}
