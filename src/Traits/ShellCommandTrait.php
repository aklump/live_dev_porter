<?php

namespace AKlump\LiveDevPorter\Traits;


use RuntimeException;

trait ShellCommandTrait {

  /**
   * Wrapper for system() with exception throwing.
   *
   * @param string $command
   *
   * @return string
   *
   * @throws \RuntimeException If result code is not 0.
   */
  public function system(string $command): string {
    $result = system($command, $result_code);
    if (0 !== $result_code) {
      throw new RuntimeException(sprintf('Failed: %s', $command));
    }

    return $result;
  }

  /**
   * Wrapper for exec() with exception throwing.
   *
   * @param string $command
   * @param array &$output
   *
   * @return string
   *
   * @throws \RuntimeException If result code is not 0.
   */
  public function exec(string $command, array &$output = []): string {
    $result = exec($command . ' 2>/dev/null', $output, $result_code);
    if (0 !== $result_code) {
      $message = '';
      $message .= sprintf("exec() status: %d", $result_code) . PHP_EOL;
      $message .= "Command: ";
      if (strstr($command, PHP_EOL) !== FALSE) {
        $message .= PHP_EOL;
      }
      $message .= $command . PHP_EOL;
      if ($output) {
        $message .= PHP_EOL . "Output: " . PHP_EOL;
        $message .= implode(PHP_EOL, $output) . PHP_EOL;
      }
      throw new RuntimeException($message, $result_code);
    }

    return $result;
  }

}
