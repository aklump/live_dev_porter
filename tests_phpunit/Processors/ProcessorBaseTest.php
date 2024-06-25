<?php

namespace AKlump\LiveDevPorter\Tests\Processors;

use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Processors\ProcessorBase
 */
class ProcessorBaseTest extends TestCase {

  use TestWithFilesTrait;

  public function testFoo() {
    $expected = 'config.local.prod.yml';
    $processor_config = [
      'FILEPATH' => $this->getTestFileFilepath($expected),
    ];
    $obj = new ProcessorBaseTestable($processor_config);
    $name = $obj->getBasename();
    $this->assertSame($expected, $name);
  }
}

class ProcessorBaseTestable extends ProcessorBase {

}
