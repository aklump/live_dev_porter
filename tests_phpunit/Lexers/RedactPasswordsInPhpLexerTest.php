<?php

namespace Lexers;

use AKlump\LiveDevPorter\Lexers\RedactPasswordsInPhpLexer;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Lexers\RedactPasswordsInPhpLexer
 */
final class RedactPasswordsInPhpLexerTest extends TestCase {

  public function testConstants() {
    $this->assertNotEmpty(RedactPasswordsInPhpLexer::REGEX_KEY);
    $this->assertNotEmpty(RedactPasswordsInPhpLexer::T_VAR_ASSIGNMENT);
  }

}
