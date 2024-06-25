<?php

namespace AKlump\LiveDevPorter\Tests\Integration;

use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithCLITrait;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

/**
 * @coversNothing
 */
class CacheTest extends TestCase {

  use TestWithFilesTrait;
  use TestWithCLITrait;

  public function testCachedJsonContainsCorrectAppRoot() {
    $dir = $this->getCloudyCacheDir() . '/_cached.live_dev_porter.config.json';
    $data = json_decode(file_get_contents($dir), TRUE);
    $expected = realpath($this->getTestFilesDirectory() . '/../../');
    $this->assertSame($expected, $data['__cloudy']['APP_ROOT']);
  }

  protected function setUp(): void {
    $dir = $this->getCloudyCacheDir();
    $json = "$dir/_cached.live_dev_porter.config.json";
    if (file_exists($json)) {
      unlink($json);
    }
    $this->ldp('help');
  }


  protected function tearDown(): void {
    $this->deleteTestFile($this->getTestLogfile());
  }

}
