<?php

namespace Security;

use AKlump\LiveDevPorter\Processors\ProcessorModes;
use AKlump\LiveDevPorter\Security\Redactor;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Security\Redactor
 * @uses   \AKlump\LiveDevPorter\Processors\DetectProcessorMode
 */
class RedactorTextTest extends TestCase {

  use TestWithFilesTrait;

  public function testThrowsWhenFindRegexHasNoPatternAndRegExpDoesntEvenMatch() {
    $contents = 'lorem ipsum';
    $redactor = (new Redactor($contents, ProcessorModes::TXT));
    $this->expectException(InvalidArgumentException::class);
    $this->expectExceptionMessage('Regexp "example\.com/cron/.+" must capture one group that identifies the portion to be replaced');
    $redactor->find(['example\.com/cron/.+'])->redact();
  }
  public function testThrowsWhenFindRegexHasNoPattern1() {
    $filepath = $this->getTestFileFilepath('crontab.bak');
    $contents = file_get_contents($filepath);
    $redactor = (new Redactor($contents, ProcessorModes::TXT));
    $this->expectException(InvalidArgumentException::class);
    $this->expectExceptionMessage('Regexp "example\.com/cron/.+" must capture one group that identifies the portion to be replaced');
    $redactor->find(['example\.com/cron/.+'])->redact();
  }

  public function testReplacesWithDefaultReplacement() {
    $filepath = $this->getTestFileFilepath('crontab.bak');
    $contents = file_get_contents($filepath);

    $redactor = (new Redactor($contents, ProcessorModes::TXT));
    $message = $redactor->find(['example\.com/cron/(.+)'])
      ->redact()
      ->getMessage();
    $this->assertStringContainsString('example.com/cron/REDACTED', $contents);
    $this->assertStringNotContainsString('PMmmET7uYuw-KFMwxjy6juUE-wvpuG.2YtRrXmrEujowG8.Ax_*VVWN_nHcMV6UTGQ!MsxM_ps', $contents);
    $this->assertStringContainsString('example\.com/cron/(.+) has been redacted', $message);
  }
  public function testReplacesWithCustomReplacement() {
    $filepath = $this->getTestFileFilepath('crontab.bak');
    $contents = file_get_contents($filepath);

    $redactor = (new Redactor($contents, ProcessorModes::TXT));
    $message = $redactor->find(['example\.com/cron/(.+)'])
      ->replaceWith('**********')
      ->redact()
      ->getMessage();
    $this->assertStringContainsString('example.com/cron/**********', $contents);
    $this->assertStringNotContainsString('PMmmET7uYuw-KFMwxjy6juUE-wvpuG.2YtRrXmrEujowG8.Ax_*VVWN_nHcMV6UTGQ!MsxM_ps', $contents);
    $this->assertStringContainsString('example\.com/cron/(.+) has been redacted', $message);
  }

}
