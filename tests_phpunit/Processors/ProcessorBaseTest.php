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
    $this->assertSame($expected, $obj->getBasenamePublic());
    $this->assertSame($processor_config['FILEPATH'], $obj->getFilepathPublic());
    $this->assertSame('yml', $obj->getExtensionPublic());
  }
}

class ProcessorBaseTestable extends ProcessorBase {

  public function getBasenamePublic() {
    return $this->getBasename();
  }

  public function getFilepathPublic() {
    return $this->getFilepath();
  }

  public function getExtensionPublic() {
    return $this->getExtension();
  }
}
