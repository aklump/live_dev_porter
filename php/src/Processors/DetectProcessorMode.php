<?php

namespace AKlump\LiveDevPorter\Processors;

use Exception;
use Symfony\Component\Yaml\Yaml;

class DetectProcessorMode {

  /**
   * @param string $contents
   *
   * @return int
   *   The detected mode or -1 if failure.
   *
   * @see \AKlump\LiveDevPorter\Processors\ProcessorModes
   */
  public function __invoke(string $contents): int {
    if (preg_match('#^\s*<\?php#', $contents)) {
      return ProcessorModes::PHP;
    }
    elseif (preg_match('#^.+=.*\n#', $contents)) {
      return ProcessorModes::ENV;
    }
    try {
      Yaml::parse($contents);

      return ProcessorModes::YAML;
    }
    catch (Exception $exception) {
      // Purposefully left blank.
    }

    return -1;
  }

}
