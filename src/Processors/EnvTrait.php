<?php

namespace AKlump\LiveDevPorter\Processors;

/**
 * To be used to sanitize .env files.
 */
trait EnvTrait {

  /**
   * Replace the the secret value of an assignment with a placeholder
   *
   * @code
   * # Before
   * FOO=PGgWcC054cNoZCCkp1KTO2It
   * # After
   * FOO=HIDDN
   * @endcode
   *
   * @param string $contents
   *   The contents of the file.
   * @param string $variable_name
   *   The name to search for.
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
   * @param string $contents
   *   The contents of the file.
   * @param string $variable_name
   *   The name to search for.
   * @param string $replace_with
   *   The value to replace the password with.
   *
   * @return string
   *   The sanitized string if $variable_name was found.
   */
  protected function envReplaceUrlPassword(string $variable_name, string $replace_with = "PASSWORD") {
    $this->validateFileIsLoaded();
    if (empty($this->loadedFile['contents'])) {
      return;
    }
    $this->loadedFile['contents'] = preg_replace_callback('/(' . preg_quote($variable_name) . '=)(.+)$/m', function ($matches) use ($replace_with) {
      $url = parse_url($matches[2]);
      $url['pass'] = $replace_with;
      $host_port = rtrim($url['host'] . ':' . ($url['port'] ?? ''), ':');
      $replace = sprintf('%s://%s:%s@%s%s', $url['scheme'], $url['user'], $url['pass'], $host_port, $url['path']);

      return str_replace($matches[2], $replace, $matches[0]);
    }, $this->loadedFile['contents']);
  }

}
