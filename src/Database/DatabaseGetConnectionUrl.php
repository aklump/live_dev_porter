<?php

namespace AKlump\LiveDevPorter\Database;

use AKlump\LiveDevPorter\Traits\HasConfigOnlyConstructorTrait;

class DatabaseGetConnectionUrl {

  use HasConfigOnlyConstructorTrait;

  /**
   * @param string $environment_id
   * @param string $database_id
   *
   * @return string
   *    The path to a certain db.cnf file.
   */
  public function __invoke(string $environment_id, string $database_id): string {
    $defaults_file = (new DatabaseGetDefaultsFile($this->config))($environment_id, $database_id);
    $cnf = file_get_contents($defaults_file);
    preg_match_all("/^(.+)=(.+)$/m", $cnf, $matches);
    if (!$matches) {
      throw new \RuntimeException(sprintf('Cannot parse defaults file: %s', $defaults_file));
    }
    $values = array_map(function ($value) {
      return trim($value, '"');
    }, $matches[2]);
    $creds = array_combine($matches[1], $values);
    $url = sprintf('mysql://%s:%s@%s', $creds['user'], 'PASSWORD', $creds['host']);
    if (!empty($creds['port'])) {
      $url .= ':' . $creds['port'];
    }
    $url .= '/';

    return $url;
  }

}
