<?php

namespace AKlump\LiveDevPorter\Database;

use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;
use AKlump\LiveDevPorter\Helpers\EscapeDoubleQuotes;
use AKlump\LiveDevPorter\Traits\ShellCommandTrait;

/**
 * Table provider that uses MySql to determine the list.
 */
class MySqlTableListProvider implements TableListProviderInterface {

  const SEP = ' ';

  use ShellCommandTrait;

  /**
   * @var \AKlump\LiveDevPorter\Config\RuntimeConfigInterface
   */
  protected $config;

  /**
   * @var string
   */
  protected $env;

  /**
   * @var string
   */
  protected $db;

  public function __construct(RuntimeConfigInterface $config, string $environment_id, string $database_id) {
    $this->config = $config;
    $this->env = $environment_id;
    $this->db = $database_id;
  }

  /**
   * @inheritDoc
   */
  public function get(string $conditions): array {
    $query = "SET group_concat_max_len = 40960;";
    $database_name = (new DatabaseGetName($this->config))($this->env, $this->db);
    $query .= sprintf("SELECT GROUP_CONCAT(table_name separator '%s') FROM information_schema.tables WHERE table_schema='%s' AND (%s)", self::SEP, $database_name, $conditions);
    $defaults_file = (new DatabaseGetDefaultsFile($this->config))($this->env, $this->db);
    $query = (new EscapeDoubleQuotes())($query);
    $command = sprintf('mysql --defaults-file="%s" -AN -e "%s"', $defaults_file, $query);

    return explode(self::SEP, $this->exec($command));
  }

}
