<?php

namespace AKlump\LiveDevPorter\Tests\TestHelpers;


use AKlump\LiveDevPorter\Config\RuntimeConfig;
use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;

trait TestWithConfigTrait {

  public function getConfig(string $db_id = 'database', string $workflow_id = 'workflow', array $workflow_database_config = []): RuntimeConfigInterface {
    return new RuntimeConfig([
      'CACHE_DIR' => sys_get_temp_dir() . '/LiveDevPorterTests',
      'workflows' => [$workflow_id => ['databases' => [$db_id => $workflow_database_config]]]
    ]);
  }

}
