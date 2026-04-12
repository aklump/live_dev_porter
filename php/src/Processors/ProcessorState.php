<?php

namespace AKlump\LiveDevPorter\Processors;

/**
 * Processors should return this object to indicate progress.
 */
class ProcessorState {

  /**
   * @var float
   */
  protected $progressRatio;

  /**
   * @param float $progress_ratio A value from 0 to 1 indicating how far along
   * the process is, where 1.0 is complete
   */
  public function __construct(float $progress_ratio) {
    $this->progressRatio = $progress_ratio;
  }

  public function getProgressRatio(): float {
    return $this->progressRatio;
  }
}
