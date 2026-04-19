<?php

namespace AKlump\LiveDevPorter\FixtureFramework;

use AKlump\FixtureFramework\Fixture;
use AKlump\FixtureFramework\FixtureInterface;
use AKlump\FixtureFramework\Runtime\FixtureRunner;
use AKlump\FixtureFramework\Helper\FixtureInstantiator;
use AKlump\FixtureFramework\Helper\GetFixtures;
use AKlump\FixtureFramework\Helper\GetFixtureIdByClassname;
use AKlump\FixtureFramework\Discovery\DiscoverFixtureDefinitions;
use AKlump\FixtureFramework\Runtime\RunContextStore;
use AKlump\FixtureFramework\Runtime\RunContextValidator;
use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Processors\ProcessorFailedException;
use AKlump\LiveDevPorter\Processors\ProcessorSkippedException;
use AKlump\LiveDevPorter\Processors\ProcessorState;

abstract class AbstractFixtureRunner extends ProcessorBase {

  protected $fixturesLoaded = FALSE;

  protected $fixtureIndex = [];

  protected $totalFixtures = 0;

  /**
   * @var \AKlump\FixtureFramework\RunContextStore
   */
  protected $contextStore;

  /**
   * @var \AKlump\FixtureFramework\RunContextValidator
   */
  protected $contextValidator;

  /**
   * @return array The value for $global_options
   *
   * @see \AKlump\FixtureFramework\FixtureRunner::__construct
   */
  abstract protected function getGlobalOptions(): array;

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
  abstract protected function tryCanProcessFixture(FixtureInterface $fixture): void;

  public function __invoke(): ProcessorState {

    /**
     * First run, load the fixtures.
     */
    if (!$this->fixturesLoaded) {
      $this->loadFixtures();
    }

    /**
     * Get the next fixture record, skipping on exception.
     */
    $fixture = NULL;
    while (empty($fixture) && count($this->fixtureIndex)) {
      $fixture = $this->getNextFixture();
    }

    /**
     * Run one fixture.
     */
    if (!empty($fixture)) {
      $this->runFixture($fixture, FALSE);
    }

    /**
     * Handle the output/progress.
     */
    print PHP_EOL . PHP_EOL;
    $progress_ratio = $this->fixtureIndex ? count($this->fixtureIndex) / $this->totalFixtures : 1;

    return new ProcessorState($progress_ratio);
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

  private function loadFixtures() {
    $flush = (bool) ($this->getProcessorOptions()['flush'] ?? FALSE);
    $filter = $this->getProcessorOptions()['filter'] ?? '';

    // The vendor directory is required for the fixture framework, as that is
    // how classes are discovered.
    $vendor_dir = $this->getVendorDirectory();
    if (!file_exists($vendor_dir . '/autoload.php')) {
      throw new \RuntimeException('Unable to locate composer autoload.php file in ' . $vendor_dir);
    }
    require_once $vendor_dir . '/autoload.php';

    try {
      // Any output from this causes problems with JSON parsing so the quiet
      // flag must not change to TRUE!!!!!
      $this->fixtureIndex = (new DiscoverFixtureDefinitions())($vendor_dir, [
        'AKlump\LiveDevPorter\Fixture',
      ], $flush, TRUE, $filter);
      $this->fixturesLoaded = TRUE;
      $this->totalFixtures = count($this->fixtureIndex);
      $this->contextStore = new RunContextStore();
      $this->contextValidator = new RunContextValidator();
    }
    catch (\Exception $e) {
      throw new ProcessorFailedException('Error ordering fixtures: ' . $e->getMessage());
    }
  }

  private function getNextFixture(): ?FixtureInterface {
    $fixture_record = array_shift($this->fixtureIndex);

    // Instantiate the fixture before processing checks because eligibility may
    // depend on runtime state injected during construction, such as options,
    // run context, or values produced by earlier fixtures. A fixture record
    // only contains static metadata and is not sufficient for decisions that
    // depend on the live fixture instance.
    $fixture = (new FixtureInstantiator())($fixture_record, $this->getGlobalOptions(), $this->contextStore, $this->contextValidator);

    try {
      $this->tryCanProcessFixture($fixture);
    }
    catch (ProcessorSkippedException $exception) {
      print sprintf('Skipping fixture "%s" (%s).', $fixture->id(), get_class($fixture)) . PHP_EOL . PHP_EOL . PHP_EOL;
      unset($fixture);
    }

    return $fixture;
  }

  private function runFixture(FixtureInterface $fixture, bool $silent) {
    try {
      $stash = getcwd();
      if ($stash === FALSE) {
        throw new \RuntimeException('Unable to determine the current working directory.');
      }

      $base_path = $this->getHostProjectBasePath();
      if (!chdir($base_path)) {
        throw new \RuntimeException(sprintf('Unable to change working directory to "%s".', $base_path));
      }

      $runner = new FixtureRunner([$fixture]);
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
    }
  }


}
