<?php

namespace AKlump\LiveDevPorter\Lexers;

use AKlump\LiveDevPorter\Processors\RedactPasswords;
use Doctrine\Common\Lexer\AbstractLexer;

class RedactPasswordsInBashLexer extends AbstractLexer {

  const T_VAR_ASSIGNMENT = 1;

  const T_URL_ASSIGNMENT = 2;

  const REGEX_KEY = '^([^=\s]+)=';

  const REGEX_URL_PW = ':\/\/.+?:(.+?)@';

  /**
   * @inheritDoc
   */
  protected function getCatchablePatterns() {
    return [
      ".+?=.+?:\/\/.+?:.+?@[^\n]+",
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
    if (preg_match('#' . self::REGEX_URL_PW . '#', $value)) {
      return self::T_URL_ASSIGNMENT;
    }
    if (preg_match('#' . self::REGEX_KEY . '#', $value)) {
      return self::T_VAR_ASSIGNMENT;
    }

    return $type;
  }

}
