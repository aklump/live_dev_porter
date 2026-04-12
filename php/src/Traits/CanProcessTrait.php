<?php

namespace AKlump\LiveDevPorter\Traits;

use AKlump\LiveDevPorter\Processors\ProcessorSkippedException;

/**
 * Trait to handle conditional processing with a fluent interface.
 *
 * This should be added to instances of
 * \AKlump\LiveDevPorter\Processors\ProcessorBase as there are dependent methods
 * herein.
 *
 * @see \AKlump\LiveDevPorter\Processors\ProcessorBase
 *
 *
 */
trait CanProcessTrait {

  /**
   * @var string[]
   */
  private $canProcessErrors = [];

  abstract protected function getEnv(string $variable_name): string;

  /**
   * Ensure the environment is one of the allowed ones.
   *
   * @param string ...$environments
   *
   * @return $this
   */
  protected function environmentIsOneOf(string ...$environments): self {
    $current_env = $this->getEnv('LOCAL_ENV_ID');
    if (!in_array($current_env, $environments)) {
      $this->canProcessErrors[] = sprintf('Local environment is not "%s".', implode('" or "', $environments));
    }

    return $this;
  }

  /**
   * Ensure the database ID is set.
   *
   * @return $this
   */
  protected function hasDatabaseId(): self {
    if (empty($this->databaseId)) {
      $this->canProcessErrors[] = 'Database ID is not set.';
    }

    return $this;
  }

  /**
   * Ensure the command is one of the allowed ones.
   *
   * @param string ...$commands
   *
   * @return $this
   */
  protected function commandIsOneOf(string ...$commands): self {
    if (empty($this->command)) {
      $this->canProcessErrors[] = 'Command is not set.';
    }
    elseif (!in_array($this->command, $commands)) {
      $this->canProcessErrors[] = sprintf('Command is not "%s".', implode('" or "', $commands));
    }

    return $this;
  }

  /**
   * Throw an exception if any conditions were not met.
   *
   * @throws \AKlump\LiveDevPorter\Processors\ProcessorSkippedException
   */
  protected function assertCanProcess(): void {
    if (!empty($this->canProcessErrors)) {
      $message = implode(' ', $this->canProcessErrors);
      $this->canProcessErrors = [];
      throw new ProcessorSkippedException($message);
    }
  }
}
