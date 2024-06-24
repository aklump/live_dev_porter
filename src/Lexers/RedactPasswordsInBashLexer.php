<?php

namespace AKlump\LiveDevPorter\Lexers;

use AKlump\LiveDevPorter\Processors\RedactPasswords;
use Doctrine\Common\Lexer\AbstractLexer;

class RedactPasswordsInBashLexer extends AbstractLexer {

  const T_VAR_ASSIGNMENT = 1;

  const REGEX_KEY = '^([^=\s]+)=';

  /**
   * @inheritDoc
   */
  protected function getCatchablePatterns() {
    return [
      // array key assignment
      "'[^']*?'='[^']*?'",
    ];
  }

  /**
   * @inheritDoc
   */
  protected function getNonCatchablePatterns() {
    return ['#![\n]+\n', '\s+'];
  }

  /**
   * @inheritDoc
   */
  protected function getType(&$value) {
    $type = 0;
    if (preg_match('#' . self::REGEX_KEY . '#', $value)) {
      return self::T_VAR_ASSIGNMENT;
    }

    return $type;
  }

}
