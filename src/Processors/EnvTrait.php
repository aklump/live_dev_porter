<?php

namespace AKlump\LiveDevPorter\Processors;

/**
 * To be used to sanitize .env files.
 *
 * @deprecated Since version 0.0.160, Use \AKlump\LiveDevPorter\Processors\RedactPasswords instead.
 */
trait EnvTrait {

  /**
   * Replace the the secret value of an assignment with a placeholder
   *
   * @code
   * # Before
   * FOO=PGgWcC054cNoZCCkp1KTO2It
   * # After
   * FOO=""
   * @endcode
   *
   * @param string $variable_name
   *   The name to search for, e.g. "FOO"
   * @param string $replace_with
   *   The value to replace with.
   */
  protected function envReplaceValue(string $variable_name, string $replace_with = '""') {
    $this->validateFileIsLoaded();
    if (empty($this->loadedFile['contents'])) {
      return;
    }
    $this->loadedFile['contents'] = preg_replace('/(' . preg_quote($variable_name) . '=).+$/m', '$1' . $replace_with, $this->loadedFile['contents']);
  }

  /**
   * Replace the password in an URL assignment with a placeholder.
   *
   * @code
   * # Before
   * DATABASE_URL=mysql://foo:IoTXIQigB372TIhitOtH2TG7@mysql.foobar.com/barbaz
   * # After
   * DATABASE_URL=mysql://foo:PASSWORD@mysql.foobar.com/barbaz
   * @endcode
   *
   * @param string $variable_name
   *   The name to search for.
   * @param string $replace_with
   *   The value to replace the password with.
   *
   * @return string
   *   The sanitized string if $variable_name was found.
   */
  protected function envReplaceUrlPassword(string $variable_name, string $replace_with = NULL) {
    $replace_with = $replace_with ?? ProcessorBase::TOKENS__PASSWORD;
    $this->validateFileIsLoaded();
    if (empty($this->loadedFile['contents'])) {
      return;
    }
    $this->loadedFile['contents'] = preg_replace_callback('/(' . preg_quote($variable_name) . '=)(.+)$/m', function ($matches) use ($replace_with) {
      $url = parse_url(trim($matches[2], '\'" '));
      $url['pass'] = $replace_with;
      $host_port = rtrim($url['host'] . ':' . ($url['port'] ?? ''), ':');
      $replace = sprintf('%s://%s:%s@%s%s', $url['scheme'] ?? '', $url['user'] ?? 'USER', $url['pass'] ?? 'PASS', $host_port, $url['path'] ?? '');

      return str_replace($matches[2], $replace, $matches[0]);
    }, $this->loadedFile['contents']);
  }

}
