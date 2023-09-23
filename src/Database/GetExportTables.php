<?php

namespace AKlump\LiveDevPorter\Database;

use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;

class GetExportTables {

  const STRUCTURE = 1;

  const DATA = 2;

  /**
   * @var \AKlump\LiveDevPorter\Config\RuntimeConfigInterface
   */
  protected $config;

  /**
   * @var \AKlump\LiveDevPorter\Database\TableListProviderInterface|null
   */
  protected $provider;

  public function __construct(RuntimeConfigInterface $config, TableListProviderInterface $list_provider = NULL) {
    $this->config = $config;
    $this->provider = $list_provider;
  }

  /**
   * Get a list of tables for a given workflow and context.
   *
   * @param string $environment_id
   * @param string $database_id
   * @param string $database_name
   * @param string $workflow_id
   * @param int $options
   *
   * @return array
   *   The appropriate set of tablenames.
   */
  public function __invoke(string $environment_id, string $database_id, string $database_name, string $workflow_id, int $options): array {
    $prefix = "workflows.$workflow_id.databases.$database_id";

    // Determine if in/ex-clusive.
    $include_table_data = $this->config->get("$prefix.include_table_data") ?? [];
    $include_tables = $this->config->get("$prefix.include_tables") ?? [];

    $type = GetTableQuery::EXCLUSIVE;
    if (!empty($include_table_data) || !empty($include_tables)) {
      $type = GetTableQuery::INCLUSIVE;
    }

    $provider = $this->provider ?? new MySqlTableListProvider($this->config, $environment_id, $database_id);

    if (GetTableQuery::INCLUSIVE === $type) {
      $tables = $include_table_data;
      if ($options & self::STRUCTURE) {
        $tables = array_unique(array_merge($tables, $include_tables));
      }
      if ($tables && !self::hasWildcard($tables)) {
        // An early return because the db needn't be queried for any table
        // information.  We have the tables indicated distinctly in the
        // configuration so just return.
        return self::format($tables);
      }
    }
    elseif (GetTableQuery::EXCLUSIVE === $type) {
      if ($options & self::STRUCTURE) {
        $tables = $this->config->get("$prefix.exclude_tables") ?? [];
      }
      elseif ($options & self::DATA) {
        $tables = $this->config->get("$prefix.exclude_table_data") ?? [];
      }
    }

    if ($tables) {
      $query = (new GetTableQuery())($tables, $type);
      $tables = $provider->get($query);
    }

    return self::format($tables ?? []);
  }

  private static function hasWildcard(array $tables) {
    return !empty(array_filter($tables, function ($name) {
      if (strstr($name, GetTableQuery::WILDCARD)) {
        return TRUE;
      }
      if (strstr($name, GetTableQuery::WILDCARD_ALIAS)) {
        return TRUE;
      }

      return FALSE;
    }));
  }

  private static function format(array $tables) {
    sort($tables);

    return $tables;
  }

}
