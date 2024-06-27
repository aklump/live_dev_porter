<?php

namespace Security;

use AKlump\LiveDevPorter\Security\Redactor;
use PHPUnit\Framework\TestCase;
use RuntimeException;

/**
 * @covers \AKlump\LiveDevPorter\Security\Redactor::getReplacement()
 * @covers \AKlump\LiveDevPorter\Security\Redactor::setMode()
 * @uses   \AKlump\LiveDevPorter\Security\Redactor
 * @uses   \AKlump\LiveDevPorter\Processors\DetectProcessorMode
 */
class RedactorTest extends TestCase {

  public function testInvalidModeThrowsOnConstruct() {
    $this->expectException(RuntimeException::class);
    $contents = 'lorem ipsum';
    new Redactor($contents, time());
  }

  public function testInvalidModeThrows() {
    $this->expectException(RuntimeException::class);
    $contents = 'lorem ipsum';
    (new Redactor($contents, time()))->redact();
  }

  public function testGetReplacement() {
    $replacement = '***';
    $contents = 'lorem ipsum';
    $redactor = (new Redactor($contents))->replaceWith($replacement);
    $this->assertSame($replacement, $redactor->getReplacement());
  }

}
