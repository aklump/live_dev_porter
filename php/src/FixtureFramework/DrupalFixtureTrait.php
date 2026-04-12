<?php

namespace AKlump\LiveDevPorter\FixtureFramework;

use AKlump\FixtureFramework\Exception\FixtureException;

/**
 * Provides utility methods for managing Drupal modules and caching
 * during automated testing using Drush commands.
 *
 * Callers must provide an $options property
 *
 * @see \AKlump\FixtureFramework\Traits\FixtureOptionsTrait
 */
trait DrupalFixtureTrait {

  protected function cacheRebuild(): void {
    $drush = $this->options->require('drush');
    system("$drush cache:rebuild -y", $result_code);
    if ($result_code !== 0) {
      throw new FixtureException("Failed to rebuild cache.");
    }
  }

  /**
   * Enables the specified modules that are not already enabled.
   *
   * @param array $modules The list of module names to be enabled.
   *
   * @return void
   */
  protected function enableModules(array $modules) {
    $drush = $this->options->require('drush');
    $enabled = $this->getEnabledModules();
    $modules = array_diff($modules, $enabled);
    if (empty($modules)) {
      return;
    }
    $modules = implode(',', $modules);
    system("$drush en \"$modules\" -y");
  }

  /**
   * Disables the specified modules that are currently enabled.
   *
   * @param array $modules The list of module names to be disabled.
   *
   * @return void
   */
  protected function disableModules(array $modules) {
    $enabled = $this->getEnabledModules();
    $modules = array_intersect($modules, $enabled);
    if (empty($modules)) {
      return;
    }
    $modules = implode(',', $modules);
    $drush = $this->options->require('drush');
    system("$drush pm:uninstall \"$modules\" -y");
  }

  /**
   * Retrieves the list of currently enabled modules.
   *
   * @return array An array containing the names of enabled modules.
   *
   * @throws FixtureException If the command to retrieve the enabled modules fails.
   */
  protected function getEnabledModules(): array {
    $drush = $this->options->require('drush');
    $command = "$drush pm:list --status=enabled --format=json";
    exec($command, $output, $result_code);
    if ($result_code !== 0) {
      throw new FixtureException("Failed to get enabled modules list.");
    }

    $json = $this->extractJsonFromOutput($output);
    $data = json_decode($json, TRUE);

    return array_keys($data);
  }

  /**
   * Extracts a JSON string from the provided output array by trimming
   * any extraneous data before the opening '{' and after the closing '}'.
   *
   * @param array $output The array of strings from which the JSON string will be extracted.
   *
   * @return string The extracted JSON string.
   */
  private function extractJsonFromOutput(array $output): string {
    while ($output[0] !== '{' && $output) {
      array_shift($output);
    }
    while (last($output) !== '}' && $output) {
      array_pop($output);
    }

    return implode('', $output);
  }

}
