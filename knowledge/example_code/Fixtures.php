<?php

namespace AKlump\LiveDevPorter\Processors;

final class Fixtures extends \AKlump\LiveDevPorter\FixtureFramework\AbstractFixtureRunner {

  use \AKlump\LiveDevPorter\Traits\CanProcessTrait;

  protected function getGlobalOptions(): array {
    return [];
  }

  protected function tryCanProcessFixture(\AKlump\FixtureFramework\FixtureInterface $fixture): void {
    $this
      ->environmentIsOneOf('dev')
      ->hasDatabaseId()
      ->commandIsOneOf('pull', 'import')
      ->assertCanProcess();
  }

}
