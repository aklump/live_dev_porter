<?php

namespace Database;

use AKlump\LiveDevPorter\Database\GetTableQuery;

/**
 * @covers \AKlump\LiveDevPorter\Database\GetTableQuery
 */
class GetTableQueryTest extends \PHPUnit\Framework\TestCase {

  public function dataFortestInvokeProvider() {
    $tests = [];
    $tests[] = [
      ['do', 're'],
      "table_name IN ('do','re')",
      "table_name NOT IN ('do','re')",
    ];
    $tests[] = [
      ['cache*'],
      "table_name LIKE 'cache%'",
      "table_name NOT LIKE 'cache%'",
    ];
    $tests[] = [
      ['cache%'],
      "table_name LIKE 'cache%'",
      "table_name NOT LIKE 'cache%'",
    ];
    $tests[] = [
      ['zoo%', '%art_museum%'],
      "table_name LIKE '%art_museum%' OR table_name LIKE 'zoo%'",
      "table_name NOT LIKE '%art_museum%' AND table_name NOT LIKE 'zoo%'",
    ];

    // Next 2: Ensure order doesn't matter on the output Query
    $tests[] = [
      ['cache*', 'registry'],
      "table_name LIKE 'cache%' OR table_name IN ('registry')",
      "table_name NOT LIKE 'cache%' AND table_name NOT IN ('registry')",
    ];
    $tests[] = [
      ['registry', 'cache*'],
      "table_name LIKE 'cache%' OR table_name IN ('registry')",
      "table_name NOT LIKE 'cache%' AND table_name NOT IN ('registry')",
    ];

    return $tests;
  }

  /**
   * @dataProvider dataFortestInvokeProvider
   */
  public function testInvokeWithInclusive(array $tables, string $expected_inclusive, string $expected_exclusive) {
    $result = (new GetTableQuery())($tables, GetTableQuery::INCLUSIVE);
    $this->assertSame($expected_inclusive, $result);
    $result = (new GetTableQuery())($tables, GetTableQuery::EXCLUSIVE);
    $this->assertSame($expected_exclusive, $result);
  }

}
