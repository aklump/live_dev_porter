<?php

namespace AKlump\LiveDevPorter\Tests\Database;

use AKlump\LiveDevPorter\Database\DatabaseGetConnectionUrl;
use AKlump\LiveDevPorter\Tests\TestHelpers\TestWithConfigTrait;
use AKlump\LiveDevPorter\Tests\TestHelpers\TestWithDefaultsFileTrait;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Database\DatabaseGetConnectionUrl
 * @uses \AKlump\LiveDevPorter\Config\RuntimeConfig
 * @uses \AKlump\LiveDevPorter\Database\DatabaseGetPathToDefaultsFile
 */
class DatabaseGetConnectionUrlTest extends TestCase {

  use TestWithConfigTrait;
  use TestWithDefaultsFileTrait;

  public function dataFortestInvokeProvider() {
    $tests = [];
    $tests[] = [
      'admin',
      '127.0.0.1',
      50884,
    ];
    $tests[] = [
      'user',
      'localhost',
      3306,
    ];

    return $tests;
  }

  /**
   * @dataProvider dataFortestInvokeProvider
   */
  public function testInvoke($user, $host, $port) {
    $env = 'develop';
    $db_id = 'database';
    $config = $this->getConfig($db_id);
    $this->createDefaultsFile($config, $env, $db_id, $user, $host, $port);

    $result = (new DatabaseGetConnectionUrl($config))($env, $db_id);
    $this->assertSame("mysql://$user:PASSWORD@$host:$port/", $result);
  }

}
