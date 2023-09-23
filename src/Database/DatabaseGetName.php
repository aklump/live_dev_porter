<?php

namespace AKlump\LiveDevPorter\Database;

use AKlump\LiveDevPorter\Traits\CanCallPluginsTrait;
use AKlump\LiveDevPorter\Traits\HasConfigOnlyConstructorTrait;
use AKlump\LiveDevPorter\Traits\ShellCommandTrait;

class DatabaseGetName {

  use HasConfigOnlyConstructorTrait;
  use ShellCommandTrait;
  use CanCallPluginsTrait;

  public function __invoke(string $environment_id, string $database_id): string {
    $path = "environments.$environment_id.databases.$database_id.plugin";
    $plugin = $this->config->get($path);
    if (!$plugin) {
      throw new \RuntimeException(sprintf('Missing plugin empty configuration value for %s', $path));
    }

    return (string) $this->callPlugin($plugin, 'database_name', $environment_id, $database_id);
  }
}
