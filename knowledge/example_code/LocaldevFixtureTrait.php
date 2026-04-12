<?php

namespace AKlump\LiveDevPorter\Traits;

/**
 * Provides helper methods for managing local development fixtures.
 *
 * This trait is designed to assist in processing and verifying
 * environmental conditions specific to local development workflows.
 */
trait LocaldevFixtureTrait {

  use \AKlump\LiveDevPorter\Traits\CanProcessTrait;

  protected function tryCanProcess(): void {
    $this
      ->environmentIsOneOf('dev')
      ->hasDatabaseId()
      ->commandIsOneOf('pull', 'import')
      ->assertCanProcess();
  }

  protected function getGlobalOptions(): array {
    return [
      'drush' => $this->findDrush(),
    ];
  }

  private function findDrush(): string {
    $base_path = $this->getHostProjectBasePath();
    exec("$base_path/bin/find_cli_tool.sh drush", $output, $result_code);
    if ($result_code !== 0) {
      return '';
    }

    return trim($output[0]);
  }
}
