<?php

namespace AKlump\LiveDevPorter\Tests\TestingTraits;

use RuntimeException;

trait TestWithCLITrait {

  /**
   * @var string
   */
  protected $ldpOutput;

  /**
   * Calls the Live Dev Porter shell script with the given command.
   *
   * @param string $command The command to execute, e.g. 'cc', 'help'.
   *
   * @return int The exit code of the command.
   *
   * @see $this->ldpOutput
   */
  protected function ldp(string $command): int {
    $wdir = __DIR__ . '/../../';
    exec(sprintf('cd %s && export LOGFILE="%s" && ./live_dev_porter.sh %s', $wdir, $this->getTestLogfile(), $command), $output, $exit_code);
    $this->ldpOutput = implode(PHP_EOL, $output);

    return $exit_code;
  }

  protected function getTestLogfile(): string {
    return $this->getTestFileFilepath('integration_testing.log');
  }

  protected function getTestLog(): string {
    $path = $this->getTestLogfile();
    if (!file_exists($path)) {
      throw new RuntimeException(sprintf('The test log file "%s" does not exist.  Check live_dev_porter.sh to make sure LOGFILE is commented out and try again; it could be overriding the test log.', $path));
    }

    return file_get_contents($path);
  }

  protected function getCloudyCacheDir(): string {
    $cloudy_dir = realpath(__DIR__ . '/../../cloudy');
    if (!file_exists($cloudy_dir)) {
      throw new \RuntimeException(sprintf('The cloudy directory is missing from %s; check the method %s', $cloudy_dir, __METHOD__));
    }

    return "$cloudy_dir/cache/";
  }

}
