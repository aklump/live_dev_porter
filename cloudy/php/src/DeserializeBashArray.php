<?php
/* SPDX-License-Identifier: BSD-3-Clause */

namespace AKlump\Cloudy;


/**
 * Class DeserializeBashArray
 *
 * This class is responsible for deserializing a serialized Bash array into a PHP array.
 *
 * @code
 * # Export a BASH array to the environment.
 * declare -a FOO=(do re mi "fa sol")
 * export FOO__SERIALIZED_ARRAY=$(declare -p FOO)
 * @endcode
 *
 * @code
 * # Read the exported BASH array into a PHP array from environment.
 * $FOO = (new DeserializeBashArray())(getenv('FOO__SERIALIZED_ARRAY'));
 * @endcode
 */
class DeserializeBashArray {

  public function __invoke(string $serialized_bash_array): array {
    if (preg_match('#declare -\S+ (\S+)=\'\(\)\'$#', $serialized_bash_array)) {
      return [];
    }

    if (!preg_match('#declare -\S+ (\S+)=\'\((.+)\)\'#', $serialized_bash_array, $matches)) {
      throw new \InvalidArgumentException(sprintf('Not a serialized Bash Array: %s', $serialized_bash_array));
    }
    //    $var_name = $matches[1];
    if (!preg_match_all('#\[(\d+)\]="(.+?)"#', $matches[2], $matches)) {
      throw new \InvalidArgumentException(sprintf('Not a serialized Bash Array: %s', $serialized_bash_array));
    }

    return array_combine($matches[1], $matches[2]);
  }

}
