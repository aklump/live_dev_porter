<?php

namespace Lexers;

use AKlump\LiveDevPorter\Lexers\TokenAdapter;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Lexers\TokenAdapter
 */
class TokenAdapterTest extends TestCase {

  public function testNullThrows() {
    $this->expectException(\InvalidArgumentException::class);
    new TokenAdapter(NULL);
  }

  public function testVersion2() {
    $token = new TokenVersionTwo(2);
    $token->value = 'lorem';
    $adapter = new TokenAdapter($token);
    $this->assertSame('lorem', $adapter->getValue());
    $this->assertTrue($adapter->isA(2));
  }

  public function testVersion1() {
    $token = [
      'value' => 'lorem',
      'type' => 1,
    ];
    $adapter = new TokenAdapter($token);
    $this->assertSame('lorem', $adapter->getValue());
    $this->assertTrue($adapter->isA(1));
  }

}

/**
 * A class to represent the version 2 token object for testing.
 */
class TokenVersionTwo {

  public $value;

  private $type;

  public function __construct(int $type) {
    $this->type = $type;
  }

  public function isA(int $type) {
    return $type === $this->type;
  }
}
