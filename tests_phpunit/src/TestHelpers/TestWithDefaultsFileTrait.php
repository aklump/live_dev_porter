<?php

namespace AKlump\LiveDevPorter\Tests\TestHelpers;


use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;

trait TestWithDefaultsFileTrait {

  public function createDefaultsFile(RuntimeConfigInterface $config, string $env, string $db_id, string $user, string $host = '127.0.0.1', int $port = 3306): string {
    $path = $config->get('CACHE_DIR');
    $path .= "/$env/databases/$db_id/db.cnf";
    if (!file_exists(dirname($path))) {
      mkdir(dirname($path), 0755, TRUE);
    }
    $contents = "[client]
host=\"$host\"
port=\"$port\"
user=\"$user\"
password=\"pass\"
";
    $result = file_put_contents($path, $contents);
    if (!$result) {
      throw new \RuntimeException(sprintf('Failed to create defaults file: %s', $path));
    }

    return $path;
  }
}
