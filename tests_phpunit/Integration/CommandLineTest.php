<?php

namespace Integration;

use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithCLITrait;

/**
 * @coversNothing
 */
class CommandLineTest extends TestCase {

  use TestWithFilesTrait;
  use TestWithCLITrait;

  protected $workDir;

  public function dataFortestExitCodeZeroProvider() {
    $tests = [];
    $tests[] = [
      'help',
    ];
    //    $tests[] = [
    //      'cc',
    //    ];

    return $tests;
  }

  /**
   * @dataProvider dataFortestExitCodeZeroProvider
   */
  public function testExitCodeZero(string $command) {
    $this->assertSame(0, $this->ldp($command));
  }

  public function testVersionCommand() {
    $this->assertSame(0, $this->ldp('version'));
    $this->assertMatchesRegularExpression('#Live Dev Porter version [\d.]+#', $this->ldpOutput);
  }

}
