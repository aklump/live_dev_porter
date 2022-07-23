<?php

use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Processors\ProcessorSkippedException;

/**
 * Rename files in the secrets group based on environment.
 */
final class FileGroupSecretsHandler extends ProcessorBase {

  /**
   * {@inheritdoc}
   */
  public function process() {
    if (!$this->isWriteableEnvironment() || 'secrets' !== $this->filesGroupId || !$this->loadFile()) {
      throw new ProcessorSkippedException();
    }
    $move_to = $this->getSourceBasedFilepath([
      'dev' => 'dev',
      'local' => 'dev',
      'live' => 'prod',
      'test' => 'staging',
    ]);
    if ($this->saveFile($move_to) !== FALSE) {
      return sprintf("Saved %s", basename($move_to));
    }

    throw new ProcessorSkippedException();
  }

}
