<?php

namespace AKlump\LiveDevPorter\Helpers;

class TryEnsureExecutePermissions {

  /**
   * @param string $path
   *
   * @return void
   *
   * @throws \RuntimeException If $path is not executable and we're not able to
   * update it's permission to be so.
   */
  public function __invoke(string $path) {
    if (!is_executable($path)) {
      exec(sprintf('chmod u+x %s', $path));
    }
    if (!is_executable($path)) {
      throw new \RuntimeException(sprintf('%s does not have execute permissions; fix this and try again.', $path));
    }
  }

}
