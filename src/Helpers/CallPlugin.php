<?php

namespace AKlump\LiveDevPorter\Helpers;

use AKlump\LiveDevPorter\Traits\HasConfigOnlyConstructorTrait;
use AKlump\LiveDevPorter\Traits\ShellCommandTrait;

/**
 * PHP class to call a given plugin function.
 */
class CallPlugin {

  use HasConfigOnlyConstructorTrait;
  use ShellCommandTrait;

  /**
   * @var string
   */
  private string $plugin;

  /**
   * @var string
   */
  private string $functionTail;

  /**
   * @param string $plugin_name
   * @param string $plugin_function
   *
   * @return string
   */
  public function __invoke(string $plugin_name, string $plugin_function) {
    $plugin_args = func_get_args();
    $this->plugin = array_shift($plugin_args);
    $this->functionTail = array_shift($plugin_args);

    $command = [];
    $command[] = sprintf('export APP_ROOT="%s";', $this->config->get('APP_ROOT'));
    $command[] = sprintf('export CACHE_DIR="%s";', $this->config->get('CACHE_DIR'));
    $command[] = sprintf('export CLOUDY_PHP="%s";', $this->config->get('CLOUDY_PHP'));
    $command[] = sprintf('export COMPOSER_VENDOR="%s";', $this->config->get('COMPOSER_VENDOR'));
    $command[] = sprintf('export ROOT="%s";', $this->config->get('__cloudy.ROOT'));
    $command[] = sprintf('export SOURCE_DIR="%s";', $this->config->get('SOURCE_DIR'));
    $command[] = sprintf('export PLUGIN_DIR="%s";', $this->config->get('PLUGINS_DIR'));

    // We have to include all plugins because it's possible there are
    // dependencies, this is easier than computing those dependencies.
    $command[] = sprintf('export PLUGINS="%s";', implode(' ', $this->getPlugins()));
    $command[] = sprintf('export FUNCTION="%s";', $this->getFunctionName());

    $path_to_helper = $this->config->get('SOURCE_DIR') . '/call_plugin_php_helper.sh';
    (new TryEnsureExecutePermissions())($path_to_helper);
    $command[] = "$path_to_helper " . implode(' ', $plugin_args);
    $command = implode(PHP_EOL, $command);

    return $this->exec($command);
  }

  /**
   * @return array
   *   The name of all plugins that should be included.
   */
  private function getPlugins(): array {
    return array_diff(scandir($this->config->get('PLUGINS_DIR')), ['.', '..']);
  }

  /**
   * @return string
   *
   * @see _plugin_get_func_name
   */
  private function getFunctionName(): string {
    return $this->plugin . '_on_' . $this->functionTail;
  }

}
