<?php

namespace Security;

use AKlump\LiveDevPorter\Processors\ProcessorModes;
use AKlump\LiveDevPorter\Security\Redactor;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Security\Redactor
 * @uses   \AKlump\LiveDevPorter\Processors\DetectProcessorMode
 */
class RedactorTextTest extends TestCase {

  use TestWithFilesTrait;

  public function testFoo() {
    $filepath = $this->getTestFileFilepath('crontab.bak');
    $contents = file_get_contents($filepath);

    $redactor = (new Redactor($contents, ProcessorModes::TXT));
    $messages = $redactor->find(['example\.com/cron/.+'])
      ->replaceWith('example.com/cron/REDACTED')
      ->redact()
      ->getMessage();
    $this->assertStringContainsString('example.com/cron/REDACTED', $contents);
    $this->assertStringNotContainsString('PMmmET7uYuw-KFMwxjy6juUE-wvpuG.2YtRrXmrEujowG8.Ax_*VVWN_nHcMV6UTGQ!MsxM_ps', $contents);

    $message = $redactor->getMessage();
    $this->assertStringContainsString('example\.com/cron/.+ has been redacted', $message);
  }

}
