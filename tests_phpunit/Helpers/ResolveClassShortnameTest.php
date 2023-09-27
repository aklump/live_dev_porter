<?php

namespace Helpers;

use AKlump\LiveDevPorter\Helpers\ResolveClassShortname;

/**
 * @covers \AKlump\LiveDevPorter\Helpers\ResolveClassShortname
 */
class ResolveClassShortnameTest extends \PHPUnit\Framework\TestCase {

  public function dataFortestInvokeProvider() {
    $tests = [];
    $tests[] = [
      '\AKlump\LiveDevPorter\Config\Config::get',
      'Config::get',
      '\AKlump\LiveDevPorter\Config\\',
    ];
    $tests[] = [
      '\AKlump\LiveDevPorter\Config\Config::get',
      'Config::get',
      'AKlump\LiveDevPorter\Config\\',
    ];
    $tests[] = [
      '\AKlump\LiveDevPorter\Config\Config',
      'AKlump\LiveDevPorter\Config\Config',
      'AKlump\LiveDevPorter\Config\\',
    ];
    $tests[] = [
      '\AKlump\LiveDevPorter\Config\Config',
      'Config',
      'AKlump\LiveDevPorter\Config\\',
    ];
    $tests[] = [
      '\AKlump\LiveDevPorter\Config\Config',
      'Config',
      'AKlump\LiveDevPorter\Config',
    ];

    return $tests;
  }

  /**
   * @dataProvider dataFortestInvokeProvider
   */
  public function testInvoke($expected, $shortname, $namespace) {
    $this->assertSame($expected, (new ResolveClassShortname())($shortname, $namespace));
  }
}
