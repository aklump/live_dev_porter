<?php

namespace Lexers;

use AKlump\LiveDevPorter\Lexers\RedactPasswordsInBashLexer;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Lexers\RedactPasswordsInBashLexer
 */
final class RedactPasswordsInBashLexerTest extends TestCase {

  public function testConstants() {
    $this->assertNotEmpty(RedactPasswordsInBashLexer::REGEX_URL_PW);
    $this->assertNotEmpty(RedactPasswordsInBashLexer::REGEX_KEY);
    $this->assertNotEmpty(RedactPasswordsInBashLexer::T_VAR_ASSIGNMENT);
    $this->assertNotEmpty(RedactPasswordsInBashLexer::T_URL_ASSIGNMENT);
  }

}
