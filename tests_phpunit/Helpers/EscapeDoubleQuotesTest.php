<?php

namespace Helpers;

use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Helpers\EscapeQuery
 */
class EscapeDoubleQuotesTest extends TestCase {

  public function dataFortestInvokeProvider() {
    $tests = [];
    $tests[] = [
      "table_schema='test'",
      "table_schema='test'",
    ];
    $tests[] = [
      'table_schema="test"',
      'table_schema=\\"test\\"',
    ];
    $tests[] = [
      'table_schema=\\"test\\"',
      'table_schema=\\"test\\"',
    ];

    return $tests;
  }

  /**
   * @dataProvider dataFortestInvokeProvider
   */
  public function testInvoke(string $query, string $expected) {
    $this->assertSame($expected, (new \AKlump\LiveDevPorter\Helpers\EscapeDoubleQuotes())($query));
  }

}
