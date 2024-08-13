<?php

namespace AKlump\LiveDevPorter\Lexers;

use Doctrine\Common\Lexer\AbstractLexer;

class RedactPasswordsInPhpLexer extends AbstractLexer {

  const T_VAR_ASSIGNMENT = 1;

  const REGEX_KEY = '(\w+).+?=>';

  /**
   * @inheritDoc
   */
  protected function getCatchablePatterns() {
    return [
      // array key assignment
      "'[^']*?'\s*=>\s*'[^']*?'",
    ];
  }

  /**
   * @inheritDoc
   */
  protected function getNonCatchablePatterns() {
    return ['<\?php', "\s+", ',', '=>'];
  }

  /**
   * @inheritDoc
   */
  protected function getType(&$value) {
    $type = 0;
    if (preg_match('#' . self::REGEX_KEY . '#', $value, $matches)) {
      return self::T_VAR_ASSIGNMENT;
    }

    return $type;
  }

}
