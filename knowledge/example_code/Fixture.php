<?php

namespace AKlump\LiveDevPorter\Fixture;

use AKlump\FixtureFramework\Exception\FixtureException;
use AKlump\FixtureFramework\Fixture;

#[Fixture(id: 'permissions')]
class Permissions extends \AKlump\FixtureFramework\AbstractFixture {

  private array $permissionsToAdd = [
    'anonymous' => ['access environment indicator'],
    'authenticated' => ['access environment indicator'],
  ];

  public function __invoke(): void {
    $drush = $this->options->require('drush');
    foreach ($this->permissionsToAdd as $role => $perms) {
      foreach ($perms as $perm) {
        system("$drush role:perm:add $role '$perm'", $result_code);
        if ($result_code != 0) {
          throw new FixtureException("Failed to add permissions to $role.");
        }
      }
    }
  }

}
