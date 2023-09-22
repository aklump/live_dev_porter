<?php

namespace AKlump\LiveDevPorter\Database;

interface TableListProviderInterface {

  /**
   * Get tablenames based on $table_query string.
   *
   * @param string $conditions
   *   An SQL where clause (excluding the "WHERE"), e.g. 'table_name in ("foo")
   *   OR table_name LIKE "cache%"'
   *
   * @return array
   *   An array of tablenames.
   *
   * @see \AKlump\LiveDevPorter\Database\GetTableQuery
   */
  public function get(string $conditions): array;

}
