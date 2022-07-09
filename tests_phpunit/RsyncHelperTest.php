<?php

use AKlump\LiveDevPorter\Config\RsyncHelper;
use PHPUnit\Framework\TestCase;

/**
 * @group default
 * @covers \AKlump\LiveDevPorter\Config\RsyncHelper
 */
final class RsyncHelperTest extends TestCase {

  public function testInflateRule2() {
    $rules = RsyncHelper::inflateRule('/some/path/this-file-is-found');
    $this->assertCount(3, $rules);
    $this->assertSame('/some/', $rules[0]);
    $this->assertSame('/some/path/', $rules[1]);
    $this->assertSame('/some/path/this-file-is-found', $rules[2]);
  }

  public function testInflateRule() {
    $rules = RsyncHelper::inflateRule('/.env');
    $this->assertCount(1, $rules);
    $this->assertSame('/.env', $rules[0]);
  }
}
