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
    $this->assertSame($expected, $obj->getBasename());
    $this->assertSame($processor_config['FILEPATH'], $obj->getFilepath());
    $this->assertSame('yml', $obj->getExtension());
  }
}

class ProcessorBaseTestable extends ProcessorBase {

}
