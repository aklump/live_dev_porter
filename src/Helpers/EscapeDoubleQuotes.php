<?php

namespace AKlump\LiveDevPorter\Helpers;

/**
 * Add backslash to double quotes unless already present.
 */
class EscapeDoubleQuotes {

  public function __invoke(string $query): string {
    // This is four-backslashes because of preg--confusing--that's why this
    // class exists to remove the confusion.
    return preg_replace('/(?<!\\\\)"/', '\"', $query);
  }

}
