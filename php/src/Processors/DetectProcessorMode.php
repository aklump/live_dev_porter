<?php

namespace AKlump\LiveDevPorter\Processors;

use Exception;
use Symfony\Component\Yaml\Yaml;

class DetectProcessorMode {

  /**
   * @param string $bitstream
   *
   * @return int
   *   The detected mode or -1 if failure.
   *
   * @see \AKlump\LiveDevPorter\Processors\ProcessorModes
   */
  public function __invoke(string $bitstream): int {
    if (preg_match('#^\s*<\?php#', $bitstream)) {
      return ProcessorModes::PHP;
    }
    elseif (preg_match('#^.+=.*\n#', $bitstream)) {
      return ProcessorModes::ENV;
    }
    try {
      Yaml::parse($bitstream);

      return ProcessorModes::YAML;
    }
    catch (Exception $exception) {
      // Purposefully left blank.
    }

    return ProcessorModes::TXT;
  }

}
