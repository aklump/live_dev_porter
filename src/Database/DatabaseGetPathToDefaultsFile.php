<?php

namespace AKlump\LiveDevPorter\Database;

use AKlump\LiveDevPorter\Traits\HasConfigOnlyConstructorTrait;

class DatabaseGetPathToDefaultsFile {

  use HasConfigOnlyConstructorTrait;

  /**
   * @param string $environment_id
   * @param string $database_id
   *
   * @return string
   *    The path to a certain db.cnf file.
   */
  public function __invoke(string $environment_id, string $database_id): string {
    return $this->config->get('CACHE_DIR') . "/$environment_id/databases/$database_id/db.cnf";
  }

}
