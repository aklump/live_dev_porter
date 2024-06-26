<?php

namespace AKlump\Cloudy\Tests\Unit;

use AKlump\Cloudy\Tests\Unit\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

// Do not add this to the composer autoloader as it creates strange recursions.
// Even when adding to autoload-dev.  Better to only put it here.
require_once __DIR__ . '/../php/cloudy.functions.php';

/**
 * @covers _cloudy_realpath()
 */
class CloudyRealpathTest extends TestCase {

  use TestWithFilesTrait;

  public function dataFortestInvokeProvider() {
    $tests = [];
    $root = $this->getTestFilesDirectory();

    $tests[] = [
      '{APP_ROOT}foo',
      [
        $root . 'foo',
      ],
    ];
    $tests[] = [
      '{APP_ROOT}/foo',
      [
        $root . 'foo',
      ],
    ];
    $tests[] = [
      'foo',
      [
        $root . 'foo',
      ],
    ];


    $tests[] = [
      '/lorem/foo',
      [
        '/lorem/foo',
      ],
    ];

    return $tests;
  }

  /**
   * @dataProvider dataFortestInvokeProvider
   */
  public function testInvoke(string $subject, array $expected) {
    $paths = _cloudy_realpath($subject);
    $this->assertSame($expected, $paths);
  }

  public function testGlobResolves() {
    $this->getTestFileFilepath('config/main.yml', TRUE);
    $this->getTestFileFilepath('config/local.yml', TRUE);
    $paths = _cloudy_realpath('config/*.yml');
    $this->assertCount(2, $paths);
    $this->assertSame(ROOT . "config/local.yml", $paths[0]);
    $this->assertSame(ROOT . "config/main.yml", $paths[1]);
  }

  public function testHomeResolves() {
    $home = $_SERVER['HOME'];
    $this->assertNotEmpty($home);
    $paths = _cloudy_realpath('~/foo');
    $this->assertCount(1, $paths);
    $this->assertSame("$home/foo", $paths[0]);
    $this->assertNotSame('~/foo', $paths[0]);
  }

  protected function setUp(): void {
    if (!defined('ROOT')) {
      global $_config_path_base;
      $_config_path_base = '';
      define('ROOT', $this->getTestFileFilepath('', TRUE));
      define('APP_ROOT', $this->getTestFileFilepath(''));
    }
  }

  protected function tearDown(): void {
    $this->deleteAllTestFiles();
  }


}
