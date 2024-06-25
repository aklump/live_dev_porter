<?php

namespace AKlump\LiveDevPorter\Lexers;

/**
 * This class represents a TokenAdapter.
 * A TokenAdapter is responsible for adapting a token object to provide a consistent interface for retrieving its value and checking its type between versions 1 and 2 of doctrine/lexer
 *
 * @url https://www.doctrine-project.org/projects/doctrine-lexer/en/1.2/simple-parser-example.html
 * @url https://www.doctrine-project.org/projects/doctrine-lexer/en/2.1/simple-parser-example.html
 */
class TokenAdapter {

  /**
   * @var mixed
   */
  private $token;

  public function __construct($token) {
    if (NULL === $token) {
      throw new \InvalidArgumentException('Token cannot be null.');
    }
    $this->token = $token;
  }

  public function getValue() {
    if (is_array($this->token)) {
      return $this->token['value'];
    }

    return $this->token->value;
  }

  public function isA($type): bool {
    if (is_array($this->token)) {
      return $type === $this->token['type'];
    }

    return $this->token->isA($type);
  }

}
