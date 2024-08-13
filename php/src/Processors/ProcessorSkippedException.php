<?php

namespace AKlump\LiveDevPorter\Processors;

/**
 * Called only when a processor wishes to indicate it will not be applied.
 */
class ProcessorSkippedException extends \RuntimeException {

  public function __construct($message = "") {
    parent::__construct($message, 255);
  }
}
