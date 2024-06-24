<?php

namespace AKlump\LiveDevPorter\Processors;

use AKlump\LiveDevPorter\Lexers\RedactPasswordsInPhpLexer;
use AKlump\LiveDevPorter\Lexers\RedactPasswordsInBashLexer;
use RuntimeException;
use Symfony\Component\Yaml\Yaml;

/**
 * Class RedactPasswords
 *
 * Use this class to redact passwords in serialized data.  Provide the data mode
 * using \AKlump\LiveDevPorter\Processors\ProcessorModes, the serialized
 * data/file contents, and optional configuration.
 */
class RedactPasswords {

  const DEFAULT_REPLACEMENT = 'REDACTED';

  private $replacement;

  private $customPointers;

  private $replaceableKeys;

  /**
   * @param string|NULL $replacement
   * @param array|null $replaceable_keys
   *   Leave NULL for automatic key detection; to disable set to an empty array;
   *   otherwise pass custom keys that will always be replaced.  These are
   *   different from pointers in that these are single keys e.g. "password" and
   *   do not take into account nested data such as "foo.bar.password" and
   *   "lorem.ipsum.password".
   */
  public function __construct(string $replacement = NULL, array $replaceable_keys = NULL) {
    $this->replacement = $replacement ?? self::DEFAULT_REPLACEMENT;
    $this->replaceableKeys = $replaceable_keys ?? $this->getDefaultReplaceableKeys();
  }

  /**
   * Get the default replaceable keys.
   *
   * @return array An array containing the default replaceable keys.
   */
  protected function getDefaultReplaceableKeys(): array {
    return [
      'password',
      'pass',
      'secret',
      'private_key',
      'private',
      'PASSWORD',
      'PASS',
      'SECRET',
      'PRIVATE_KEY',
      'PRIVATE',
    ];
  }

  /**
   * Process file contents based on extension and redact passwords/secrets.
   *
   * Does not save the contents; you must do that if the return value is
   * non-empty, which means contents were changed.
   *
   * @param int $processor_mode One of \AKlump\LiveDevPorter\Processors\ProcessorModes constants.
   * @param string &$contents The contents of the file to process (passed by
   * reference).
   * @param array $pointers Data pointers that should be implicitly replaced,
   * e.g. "foo.bar.password".
   *
   * @return string The message after performing redaction, if any.
   * @throws \RuntimeException If the file extension is not supported.
   *
   */
  public function __invoke(int $processor_mode, string &$contents, array $pointers = []): string {
    $this->customPointers = $pointers;
    $context = [
      'message' => '',
    ];

    switch ($processor_mode) {
      case ProcessorModes::YAML:
        $data = Yaml::parse($contents);
        $before = $data;
        $this->redactInArray($data, $context);
        if ($before !== $data) {
          $contents = Yaml::dump($data, 6, 2);
        }
        break;

      case ProcessorModes::PHP:
        $this->redactInPhp($contents, $context);
        break;

      case ProcessorModes::ENV:
        $this->redactInBash($contents, $context);
        break;

      default:
        throw new RuntimeException(sprintf('Unsupported processor mode %d.', $processor_mode));
    }

    return $context['message'];
  }

  private function redactInArray(array &$data, array &$context) {
    $context += [
      'pointer' => [],
      'message' => '',
    ];
    foreach ($data as $k => $v) {
      $pointer = implode('.', $context['pointer']);
      if ($this->doesKeyReferenceAPassword($k) || $this->shouldPointerBeReplaced(ltrim("$pointer.$k", '.'))) {
        $data[$k] = $this->replacement;
        $context['message'] .= sprintf('%s has been redacted%s', $pointer, PHP_EOL);
      }
      if (is_array($data[$k])) {
        $context['pointer'][] = $k;
        $this->redactInArray($data[$k], $context);
      }
    }
    array_pop($context['pointer']);
  }

  protected function doesKeyReferenceAPassword($k): bool {
    return in_array($k, $this->replaceableKeys);
  }

  protected function shouldPointerBeReplaced(string $pointer): bool {
    return in_array($pointer, $this->customPointers);
  }

  private function redactInPhp(string &$php_code, array &$context) {
    $lexer = new RedactPasswordsInPhpLexer();
    $lexer->setInput($php_code);
    $lexer->moveNext();
    while (TRUE) {
      if (!$lexer->lookahead) {
        break;
      }
      $lexer->moveNext();
      if ($lexer->token->isA(RedactPasswordsInPhpLexer::T_VAR_ASSIGNMENT)) {
        $find = $lexer->token->value;
        preg_match('#' . RedactPasswordsInPhpLexer::REGEX_KEY . '#', $find, $matches);
        $key = $matches[1] ?? NULL;
        if (!$key
          || (!$this->doesKeyReferenceAPassword($key) && !$this->shouldPointerBeReplaced($key))) {
          continue;
        }
        $replace = RedactPasswords::DEFAULT_REPLACEMENT;
        $replace = preg_replace('#(=>.+?)(\w+)#', '$1' . $replace, $find);
        $php_code = str_replace($find, $replace, $php_code);
        $context['message'] .= sprintf('%s has been redacted%s', $key, PHP_EOL);
      }
    }
  }

  private function redactInBash(string &$bash_code, array &$context) {
    $lexer = new RedactPasswordsInBashLexer();
    $lexer->setInput($bash_code);
    $lexer->moveNext();
    while (TRUE) {
      if (!$lexer->lookahead) {
        break;
      }
      $lexer->moveNext();
      if ($lexer->token->isA(RedactPasswordsInBashLexer::T_VAR_ASSIGNMENT)) {
        $find = $lexer->token->value;
        preg_match('#' . RedactPasswordsInBashLexer::REGEX_KEY . '#', $find, $matches);
        $key = $matches[1] ?? NULL;
        if (!$key
          || (!$this->doesKeyReferenceAPassword($key) && !$this->shouldPointerBeReplaced($key))) {
          continue;
        }
        $replace = RedactPasswords::DEFAULT_REPLACEMENT;
        $replace = preg_replace('#([^=]+=)(.*)#', '$1' . $replace, $find);
        $bash_code = str_replace($find, $replace, $bash_code);
        $context['message'] .= sprintf('%s has been redacted%s', $key, PHP_EOL);
      }
    }
  }

}
