<?php

namespace Integration;

use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithCLITrait;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

/**
 * @coversNothing
 */
class CLIConstantsTest extends TestCase {

  use TestWithFilesTrait;
  use TestWithCLITrait;

  public function testCloudyInstalledAs() {
    $contents = $this->getTestLog();
    $this->assertStringContainsString('$CLOUDY_INSTALLED_AS set to "cloudy_core"', $contents);
  }

  public function testComposerVendorIsDetectedCorrectly() {
    $contents = $this->getTestLog();
    $expected = realpath($this->getTestFilesDirectory() . '/../../') . '/vendor';
    $this->assertStringContainsString(sprintf('$COMPOSER_VENDOR is "%s"', $expected), $contents);
  }

  public function testAppRootIsDetectedCorrectly() {
    $contents = $this->getTestLog();
    $expected = realpath($this->getTestFilesDirectory() . '/../../');
    $this->assertStringContainsString(sprintf('$APP_ROOT is "%s"', $expected), $contents);
  }

  protected function setUp(): void {
    $this->deleteTestFile($this->getTestLogfile());
    $this->ldp('help');
  }


  protected function tearDown(): void {
    $this->deleteTestFile($this->getTestLogfile());
  }

}
