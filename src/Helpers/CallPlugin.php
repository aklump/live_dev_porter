<?php

namespace AKlump\LiveDevPorter\Helpers;

use AKlump\LiveDevPorter\Traits\HasConfigOnlyConstructorTrait;
use AKlump\LiveDevPorter\Traits\ShellCommandTrait;

class CallPlugin {

  use HasConfigOnlyConstructorTrait;
  use ShellCommandTrait;

  private string $name;

  private string $function;

  public function __invoke(string $plugin_name, string $plugin_function) {
    $plugin_args = func_get_args();
    $this->name = array_shift($plugin_args);
    $this->function = array_shift($plugin_args);

    $function = $this->getFunctionName();

    $command = array_map(fn($path) => "source $path", $this->getIncludePaths());
    foreach ($this->getExports() as $key => $value) {
      $command[] = "$key='$value'";
    }
    $command[] = "$function " . implode(' ', $plugin_args);
    $command = implode(';' . PHP_EOL, $command);
    $output = $this->exec($command);

    return $output;
  }

  private function getIncludePaths(): array {
    return [
      $this->config->get('__cloudy.ROOT') . '/scripts/functions.sh',
      $this->config->get('__cloudy.ROOT') . '/cloudy/inc/cloudy.api.sh',
      $this->config->get('__cloudy.ROOT') . '/cloudy/inc/cloudy.core.sh',
      $this->config->get('SOURCE_DIR') . '/database.sh',
      $this->config->get('PLUGINS_DIR') . '/' . $this->name . '/' . $this->name . '.sh',
    ];
  }


  /**
   * @return string
   *
   * @see _plugin_get_func_name
   */
  private function getFunctionName(): string {
    return $this->name . '_on_' . $this->function;
  }

  private function getExports(): array {
    return [
      'CACHE_DIR' => $this->config->get('CACHE_DIR'),
    ];
  }

}
