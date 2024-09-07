<?php

namespace Processors;

use AKlump\LiveDevPorter\Processors\DetectProcessorMode;
use AKlump\LiveDevPorter\Processors\ProcessorModes;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Processors\DetectProcessorMode
 */
final class DetectProcessorModeTest extends TestCase {

  use TestWithFilesTrait;

  public function testDetectText() {
    $filepath = $this->getTestFileFilepath('crontab.bak');
    $contents = file_get_contents($filepath);
    $this->assertSame(ProcessorModes::TXT, (new DetectProcessorMode())($contents));
  }

  public function testDetectPHP() {
    $filepath = $this->getTestFileFilepath('settings.php');
    $contents = file_get_contents($filepath);
    $this->assertSame(ProcessorModes::PHP, (new DetectProcessorMode())($contents));
  }

  public function testDetectYaml() {
    $filepath = $this->getTestFileFilepath('test.env');
    $contents = file_get_contents($filepath);
    $this->assertSame(ProcessorModes::ENV, (new DetectProcessorMode())($contents));
  }

  public function testDetectEnv() {
    $path = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($path);
    $this->assertSame(ProcessorModes::YAML, (new DetectProcessorMode())($contents));
  }

}
