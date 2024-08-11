<?php
/* SPDX-License-Identifier: BSD-3-Clause */

namespace AKlump\Cloudy;

use RuntimeException;

/**
 * Provide array support for environment variables and PHP to BASH variables.
 *
 * @code
 * // Write the value using PHP.
 * (new EnvVars('/some/cache/path.sh'))->putenv('FOO', 'bar');
 * (new EnvVars('/some/cache/path.sh'))->putenv('NOTES', ['do', 're']);
 * @endcode
 *
 * @code
 * # Read the value using BASH.
 * source '/some/cache/path.sh'
 * echo $FOO
 * echo ${NOTES[0]}
 * echo ${NOTES[1]}
 * @endcode
 *
 * @see \AKlump\Cloudy\DeserializeBashArray
 */
class EnvVars {

  const JSON_HEADER = "JSON\n";

  /**
   * @var string A filepath where the BASH source code will be written.  This
   * path needs to be sourced by BASH when you want to access the variables
   * written by this class.
   */
  private $runtimeVarsPath;

  public function __construct(string $runtime_vars_path) {
    $this->runtimeVarsPath = $runtime_vars_path;
  }

  /**
   * Set a key/value to environment vars for both PHP and BASH
   *
   * @param string $name
   * @param mixed $value Arrays are supported, however the native getenv will
   * return the value as as JSON string with special header, therefor you
   * should use this class's getenv method instead, when you anticipate working
   * with arrays.
   *
   * @return void
   */
  public function putenv(string $name, $value): void {
    $this->typecast($value);
    $this->tryValidateValue($value);

    // Arrays will get stored in PHP as JSON
    if (is_array($value)) {
      $php_assignment = "$name=" . self::JSON_HEADER . json_encode($value);
      $this->bashQuoteValue($value);
      $bash_assignment = sprintf("declare -ax $name=(%s)", implode(' ', $value));
    }
    else {
      $php_assignment = "$name=$value";
      $this->bashQuoteValue($value);
      $bash_assignment = "$name=$value";
    }

    // Set the PHP runtime environment for the course of this script.
    putenv($php_assignment);
    $this->bashWrite($bash_assignment);
  }

  public function getenv(string $name) {
    $value = getenv($name);
    preg_match('#^' . preg_quote(self::JSON_HEADER, '#') . '(.+)$#', $value, $matches);
    if (isset($matches[1])) {
      $value = $matches[1];
      $v = json_decode($value);
      if ($v && is_array($v)) {
        $value = $v;
      }
      else {
        // TODO Finish
        throw new RuntimeException(sprintf('foo',));
      }
    }
    $this->typecast($value);

    return $value;
  }

  private function typecast(&$value) {
    if (is_array($value)) {
      foreach ($value as &$v) {
        $this->typecast($v);
      }
    }
    elseif (is_numeric($value)) {
      $value *= 1;
    }
    elseif (is_bool($value)) {
      $value = $value ? 'TRUE' : 'FALSE';
    }
    elseif (is_string($value) && in_array($value, ['TRUE', 'FALSE'])) {
      $value = $value === 'TRUE';
    }
  }

  private function bashWrite(string $assignment): void {
    // TODO Can we move this to a shutdown function and do a single write to save time?
    $fh = fopen($this->runtimeVarsPath, 'a');
    fwrite($fh, $assignment . PHP_EOL);
    fclose($fh);
  }

  private function bashQuoteValue(&$value): void {
    if (is_array($value)) {
      foreach ($value as &$v) {
        $this->bashQuoteValue($v);
      }
      unset($v);
    }
    elseif (!is_numeric($value)) {
      $has_space_char = strpos($value, ' ') !== FALSE;
      $is_string_not_array = substr($value, 0, 1) == '[';
      if ($has_space_char || $is_string_not_array) {
        if (strstr($value, '"')) {
          $value = "'" . $value . "'";
        }
        else {
          $value = '"' . $value . '"';
        }
      }
    }
  }

  private function tryValidateValue($value, &$level = 0) {
    if (is_array($value)) {
      if ($level > 0) {
        throw new \InvalidArgumentException('Multidimensional arrays are not supported');
      }
      $level++;
      foreach ($value as $v) {
        $this->tryValidateValue($v, $level);
      }
    }
  }

}
