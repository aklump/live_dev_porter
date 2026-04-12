<?php

namespace AKlump\LiveDevPorter\Processors;

use AKlump\LiveDevPorter\Fixture\Permissions as PermissionsFixture;
use AKlump\LiveDevPorter\FixtureFramework\AbstractFixtureAdapter;
use AKlump\LiveDevPorter\Traits\LocaldevFixtureTrait;

final class Permissions extends AbstractFixtureAdapter {

  use LocaldevFixtureTrait;

  protected function getFixtureClass(): string {
    return PermissionsFixture::class;
  }

}
