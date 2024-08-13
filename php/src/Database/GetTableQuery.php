<?php

namespace AKlump\LiveDevPorter\Database;

class GetTableQuery {

  const WILDCARD = '%';

  const WILDCARD_ALIAS = '*';

  /**
   * All tables in $table, de-globbed if necessary.
   */
  const INCLUSIVE = 1;

  /**
   * All existing table except those in $tables, post de-globbing.
   */
  const EXCLUSIVE = 2;

  /**
   * Get the correct table list based on a configuration table list.
   *
   * @param array $tables
   *   An array of tables or table globs, e.g. ['foo', 'cache%'].  Be aware that
   *   'cache*' and 'cache%' are synonymous in this class.
   * @param int $type
   *   On of \AKlump\LiveDevPorter\Database\GetTableQuery::INCLUSIVE or
   *   \AKlump\LiveDevPorter\Database\GetTableQuery::EXCLUSIVE indicating how
   *   $tables should be understood.
   *
   * @return string
   */
  public function __invoke(array $tables, int $type): string {

    // This means we need all the tables, because we're excluding none.
    if (empty($tables) && self::EXCLUSIVE === $type) {
      return "table_name != ''";
    }

    // Normalize glob-syntax to SQL wildcards.
    $tables = array_map(function ($table) {
      return str_replace(self::WILDCARD_ALIAS, self::WILDCARD, $table);
    }, $tables);


    // Normalize order.
    sort($tables);

    $qualifier = self::EXCLUSIVE === $type ? 'NOT ' : '';
    $conditions = [];
    $in_tables = [];
    foreach ($tables as $table) {
      if (strstr($table, '%')) {
        $conditions[] = sprintf("table_name %sLIKE '%s'", $qualifier, $table);
      }
      else {
        $in_tables[] = $table;
      }
    }

    if ($in_tables) {
      $in_tables = array_map(function (string $table) {
        return "'$table'";
      }, $in_tables);
      $conditions[] = sprintf("table_name %sIN (%s)", $qualifier, implode(',', $in_tables));
    }

    return implode(self::EXCLUSIVE === $type ? ' AND ' : ' OR ', $conditions);
  }

}
