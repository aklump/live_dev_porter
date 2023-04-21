<?php

use AKlump\LiveDevPorter\Config\RsyncHelper;
use PHPUnit\Framework\TestCase;

/**
 * @group default
 * @covers \AKlump\LiveDevPorter\Config\RsyncHelper
 */
final class RsyncHelperTest extends TestCase {

  public function testInflateRuleWithDirectoryAddsDoubleAsterixExclude() {
    $rules = RsyncHelper::inflateRule('/some/path/', RsyncHelper::TYPE_EXCLUDE);
    $this->assertCount(2, $rules);
    $this->assertSame('/some/', $rules[0]);
    $this->assertSame('/some/path/', $rules[1]);
  }

  public function testInflateRuleWithDirectoryAddsDoubleAsterixInclude() {
    $rules = RsyncHelper::inflateRule('/some/path/', RsyncHelper::TYPE_INCLUDE);
    $this->assertCount(3, $rules);
    $this->assertSame('/some/', $rules[0]);
    $this->assertSame('/some/path/', $rules[1]);
    $this->assertSame('/some/path/**', $rules[2]);
  }

  public function testInflateRuleNestedDirectoriesInclude() {
    $rules = RsyncHelper::inflateRule('/some/path/this-file-is-found', RsyncHelper::TYPE_INCLUDE);
    $this->assertCount(3, $rules);
    $this->assertSame('/some/', $rules[0]);
    $this->assertSame('/some/path/', $rules[1]);
    $this->assertSame('/some/path/this-file-is-found', $rules[2]);
  }

  public function testInflateRuleNestedDirectoriesExclude() {
    $rules = RsyncHelper::inflateRule('/some/path/this-file-is-found', RsyncHelper::TYPE_EXCLUDE);
    $this->assertCount(3, $rules);
    $this->assertSame('/some/', $rules[0]);
    $this->assertSame('/some/path/', $rules[1]);
    $this->assertSame('/some/path/this-file-is-found', $rules[2]);
  }

  public function testInflateRuleIncludeFile() {
    $rules = RsyncHelper::inflateRule('/.env', RsyncHelper::TYPE_INCLUDE);
    $this->assertCount(1, $rules);
    $this->assertSame('/.env', $rules[0]);
  }

  public function testInflateRuleExcludeFile() {
    $rules = RsyncHelper::inflateRule('/.env', RsyncHelper::TYPE_EXCLUDE);
    $this->assertCount(1, $rules);
    $this->assertSame('/.env', $rules[0]);
  }

}
