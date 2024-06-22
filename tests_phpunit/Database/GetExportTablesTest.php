<?php

namespace AKlump\LiveDevPorter\Tests\Database;

use AKlump\LiveDevPorter\Database\GetExportTables;
use AKlump\LiveDevPorter\Database\MySqlTableListProvider;
use AKlump\LiveDevPorter\Database\TableListProviderInterface;
use AKlump\LiveDevPorter\Tests\TestHelpers\TestWithConfigTrait;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Database\GetExportTables
 * @uses \AKlump\LiveDevPorter\Config\RuntimeConfig
 * @uses \AKlump\LiveDevPorter\Database\GetTableQuery
 */
class GetExportTablesTest extends TestCase {

  use TestWithConfigTrait;

  public function testInvokeWithExclusiveDataNoExcludeTables() {
    $config = $this->getConfig('database', 'workflow', [
      'exclude_table_data' => ['cache_default', 'views_data'],
    ]);
    $provider = $this->getTableListProvider();

    $result = (new GetExportTables($config, $provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::DATA
    );
    $this->assertSame([
      'cache_views',
      'node',
      'watchdog',
    ], $result);
  }

  public function testInvokeWithExclusiveStructureNoExcludeTables() {
    $config = $this->getConfig('database', 'workflow', [
      'exclude_table_data' => ['cache_default', 'views_data'],
    ]);
    $provider = $this->getTableListProvider();

    $result = (new GetExportTables($config, $provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::STRUCTURE
    );
    $this->assertSame([
      'cache_default',
      'cache_views',
      'node',
      'views_data',
      'watchdog',
    ], $result);
  }


  public function testExclusiveGlobData() {
    $config = $this->getConfig('database', 'workflow', [
      'exclude_table_data' => ['watchdog', 'cache*'],
      'exclude_tables' => ['views_data'],
    ]);

    $list_provider = $this->getTableListProvider();
    $result = (new GetExportTables($config, $list_provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::DATA
    );
    $this->assertSame([
      'node',
      'views_data',
    ], $result);
  }

  public function testExclusiveGlobStructure() {
    $config = $this->getConfig('database', 'workflow', [
      'exclude_table_data' => ['watchdog'],
      'exclude_tables' => ['cache%', 'views_data'],
    ]);

    $list_provider = $this->getTableListProvider();
    $result = (new GetExportTables($config, $list_provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::STRUCTURE
    );
    $this->assertSame([
      'node',
      'watchdog',
    ], $result);
  }

  public function testInclusiveGlobData() {
    $config = $this->getConfig('database', 'workflow', [
      'include_tables_and_data' => ['watchdog', 'cache*'],
      'include_table_structure' => ['views_data'],
    ]);

    $list_provider = $this->getTableListProvider();
    $result = (new GetExportTables($config, $list_provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::DATA
    );
    $this->assertSame([
      'cache_default',
      'cache_views',
      'watchdog',
    ], $result);
  }

  public function testInclusiveGlobStructure() {
    $config = $this->getConfig('database', 'workflow', [
      'include_tables_and_data' => ['watchdog'],
      'include_table_structure' => ['cache%', 'views_data'],
    ]);

    $list_provider = $this->getTableListProvider();
    $result = (new GetExportTables($config, $list_provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::STRUCTURE
    );
    $this->assertSame([
      'cache_default',
      'cache_views',
      'views_data',
      'watchdog',
    ], $result);
  }

  public function testInvokeWithNoConfigDataReturnsAllTables() {
    $config = $this->getConfig('database', 'workflow');
    $result = (new GetExportTables($config, $this->getTableListProvider()))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::DATA
    );
    $this->assertSame([
      "cache_default",
      "cache_views",
      "node",
      "views_data",
      "watchdog",
    ], $result);
  }

  public function testInvokeWithNoConfigStructureReturnsAllTables() {
    $config = $this->getConfig('database', 'workflow');
    $result = (new GetExportTables($config, $this->getTableListProvider()))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::STRUCTURE
    );
    $this->assertSame([
      "cache_default",
      "cache_views",
      "node",
      "views_data",
      "watchdog",
    ], $result);
  }

  public function testInvokeWithInclusiveDataAndNoIncludeTablesKeyForStructureReturnsAllDataTables() {
    $config = $this->getConfig('database', 'workflow', [
      'include_tables_and_data' => [
        'block_custom',
        'field_data_body',
        'field_data_field_xml_receive',
        'field_revision_body',
        'system',
        'variable',
        'queue',
        'registry',
        'registry_file',
      ],
    ]);
    $provider = $this->getTableListProvider();

    $result = (new GetExportTables($config, $provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::STRUCTURE
    );
    $this->assertSame([
      'block_custom',
      'field_data_body',
      'field_data_field_xml_receive',
      'field_revision_body',
      'queue',
      'registry',
      'registry_file',
      'system',
      'variable',
    ], $result);
  }

  public function testInvokeWithInclusiveData() {
    $config = $this->getConfig('database', 'workflow', [
      'include_tables_and_data' => ['cache_default', 'views_data'],
      'include_table_structure' => ['watchdog', 'node'],
    ]);
    $provider = $this->createMock(TableListProviderInterface::class);
    $provider
      ->expects($this->never())
      ->method('get');

    $result = (new GetExportTables($config, $provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::DATA
    );
    $this->assertSame([
      'cache_default',
      'views_data',
    ], $result);
  }


  public function dataFortestInvokeWithInclusiveStructureProvider() {
    $tests = [];
    $tests[] = [
      [
        'include_tables_and_data' => ['node', 'views_data'],
      ],
      [
        'node',
        'views_data',
      ],
    ];
    $tests[] = [
      [
        'include_tables_and_data' => ['node', 'views_data'],
        'include_table_structure' => ['cache_default', 'cache_views'],
      ],
      [
        'cache_default',
        'cache_views',
        'node',
        'views_data',
      ],
    ];

    return $tests;
  }

  /**
   * @dataProvider dataFortestInvokeWithInclusiveStructureProvider
   */
  public function testInvokeWithInclusiveStructure(array $config, array $expected) {
    $config = $this->getConfig('database', 'workflow', $config);

    $provider = $this->createMock(TableListProviderInterface::class);
    $provider
      ->expects($this->never())
      ->method('get');

    $result = (new GetExportTables($config, $provider))(
      'dev',
      'database',
      'database',
      'workflow',
      GetExportTables::STRUCTURE
    );
    $this->assertSame($expected, $result);
  }

  protected function getTableListProvider(): TableListProviderInterface {
    $provider = $this->createMock(MySqlTableListProvider::class);
    $provider
      ->method('get')
      ->willReturnCallback(function ($query) {
        // Here is our imaginary database table set:
        // - cache_default
        // - cache_views
        // - node
        // - views_data
        // - watchdog
        switch ($query) {
          case "table_name != ''":
            return [
              'cache_default',
              'cache_views',
              'node',
              'views_data',
              'watchdog',
            ];

          case "table_name NOT IN ('cache_default','views_data')":
            return ['cache_views', 'node', 'watchdog'];

          case "table_name NOT LIKE 'cache%' AND table_name NOT IN ('watchdog')":
            return ['node', 'views_data'];

          case "table_name NOT LIKE 'cache%' AND table_name NOT IN ('views_data')":
            return ['node', 'watchdog'];

          case "table_name LIKE 'cache%' OR table_name IN ('watchdog')":
            return ['cache_default', 'cache_views', 'watchdog'];

          case "table_name LIKE 'cache%' OR table_name IN ('views_data','watchdog')":
            return ['cache_default', 'cache_views', 'views_data', 'watchdog'];

          case "table_name NOT IN ('views_data')":
            return ['cache_default', 'cache_views', 'node', 'watchdog'];

          default:
            throw new \RuntimeException(sprintf('Unexpected query: %s', $query));
        }
      });

    return $provider;
  }

}
