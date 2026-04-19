<?php

namespace AKlump\LiveDevPorter\FixtureFramework;

use AKlump\FixtureFramework\FixtureRunner;
use AKlump\FixtureFramework\Helper\GetFixtures;
use AKlump\FixtureFramework\Helper\GetFixtureIdByClassname;
use AKlump\LiveDevPorter\Fixture\Cache;
use AKlump\LiveDevPorter\Processors\ProcessorBase;

abstract class AbstractFixtureAdapter extends ProcessorBase {

  public function __invoke(): void {
    $this->tryCanProcess();

    // The vendor directory is required for the fixture framework, as that is
    // how classes are discovered.
    $vendor_dir = $this->getVendorDirectory();
    if (!file_exists($vendor_dir . '/autoload.php')) {
      throw new \RuntimeException('Unable to locate composer autoload.php file in ' . $vendor_dir);
    }
    require_once $vendor_dir . '/autoload.php';

    $flush = (bool) ($this->getProcessorOptions()['flush'] ?? FALSE);
    $silent = FALSE;

    try {
      $fixtures = (new GetFixtures())($vendor_dir, [
        (new \ReflectionClass($this->getFixtureClass()))->getNamespaceName(),
      ], $flush, $silent, $this->getFixtureId());
    }
    catch (\Exception $e) {
      echo "Error ordering fixtures: " . $e->getMessage() . "\n";
      exit(1);
    }

    try {
      $runner = new FixtureRunner($fixtures, $this->getGlobalOptions());
      $base_path = $this->getHostProjectBasePath();
      $stash = getcwd();

      if ($stash === FALSE) {
        throw new \RuntimeException('Unable to determine the current working directory.');
      }

      if (!chdir($base_path)) {
        throw new \RuntimeException(sprintf('Unable to change working directory to "%s".', $base_path));
      }

      try {
        $runner->run($silent);
      }
      finally {
        $restored = chdir($stash);
        if (!$restored) {
          error_log(sprintf('Unable to restore working directory to "%s".', $stash));
        }
      }
    }
    catch (\Throwable $e) {
      print $e->getMessage() . "\n";
      exit(1);
    }
  }

  /**
   * @throws \ReflectionException
   */
  protected function getFixtureId(): string {
    return (new GetFixtureIdByClassname())($this->getFixtureClass());
  }

  /**
   * Can this processor/fixture been applied?
   *
   * @throw \AKlump\LiveDevPorter\Processors\ProcessorSkippedException if the
   * processor should not be applied.
   *
   * @see \AKlump\LiveDevPorter\Traits\CanProcessTrait
   *
   * @code
   * $this
   *   ->environmentIsOneOf('dev')
   *   ->hasDatabaseId()
   *   ->commandIsOneOf('pull', 'import')
   *   ->assertCanProcess();
   * @endcode
   */
  protected function tryCanProcess(): void {
    // Child classes should override this method to control when the fixture is
    // processed.
  }

  /**
   * @return array The value for $global_options
   *
   * @see \AKlump\FixtureFramework\FixtureRunner::__construct
   */
  protected function getGlobalOptions(): array {
    return [];
  }

  /**
   * Get vendor directory where fixtures are located.
   *
   * @return string The vendor directory where the fixtures are located.
   *
   * Child classes may override this method to return a different directory than
   * the project's vendor directory.
   */
  protected function getVendorDirectory(): string {
    return $this->getHostProjectBasePath() . '/vendor/';
  }

  abstract protected function getFixtureClass(): string;

}
