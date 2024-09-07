<?php

namespace AKlump\LiveDevPorter\Security;

use AKlump\LiveDevPorter\Processors\DetectProcessorMode;
use AKlump\LiveDevPorter\Processors\ProcessorModes;
use ReflectionClass;
use RuntimeException;
use Symfony\Component\Yaml\Yaml;
use AKlump\LiveDevPorter\Lexers\RedactPasswordsInPhpLexer;
use AKlump\LiveDevPorter\Lexers\RedactPasswordsInBashLexer;
use AKlump\LiveDevPorter\Lexers\TokenAdapter;

class Redactor {

  const ICON = '🛡️ ';

  /**
   * @var string
   */
  private $contents;

  /**
   * @var array
   */
  private $pointerRegex;

  /**
   * @var null
   */
  private $replacement;

  /**
   * @var int
   */
  private $mode;

  /**
   * @var string
   */
  private $message;

  /**
   * Create a new redactor instance.
   *
   * @param string $contents
   * @param int|NULL $mode
   *   Leave null for auto-detection.
   *
   * @see \AKlump\LiveDevPorter\Processors\DetectProcessorMode
   * @see \AKlump\LiveDevPorter\Processors\ProcessorModes
   */
  public function __construct(string &$contents, int $mode = NULL) {
    $this->contents = &$contents;
    $this->message = '';
    if (NULL === $mode) {
      $mode = (new DetectProcessorMode())($contents);
    }
    $this->setMode($mode);
    $this->reset();
  }

  private function reset(): void {
    $this->pointerRegex = $this->getDefaultPointerRegex();
    $this->replacement = $this->getDefaultReplacement();
  }

  private function setMode(int $mode) {
    $valid = (new ReflectionClass(ProcessorModes::CLASS))->getConstants();
    if (!in_array($mode, $valid)) {
      throw new RuntimeException(sprintf('Invalid mode %s', $mode));
    }
    $this->mode = $mode;
  }

  /**
   * Optionally, control what values are redacted.
   *
   * @param array $pointer_regex
   *   An array of regex expressions, which are case-insensitive to be used to
   *   match what values are redacted.  Delimiters must not be used.
   *
   * @return $this
   *
   * @see self::getDefaultPointerRegex()
   */
  public function find(array $pointer_regex): self {
    $this->pointerRegex = $pointer_regex;

    return $this;
  }

  public function replaceWith(string $replacement): self {
    $this->replacement = $replacement;

    return $this;
  }

  protected function getDefaultPointerRegex(): array {
    return [
      'password',
      'pass',
      'secret',
      'private_key',
      'private',
    ];
  }

  protected function getDefaultReplacement(): string {
    return 'REDACTED';
  }

  public function getReplacement() {
    return $this->replacement;
  }

  public function getPointerRegex(): array {
    return $this->pointerRegex;
  }

  public function getMessage(): string {
    // Ensure message ends with newline to allow for concantenation by caller.
    if ($this->message && substr($this->message, -1 * strlen(PHP_EOL)) !== PHP_EOL) {
      $this->message .= PHP_EOL;
    }

    return $this->message;
  }

  /**
   * Redact the contents based on the mode.
   *
   * Each time, after this is called, arguments passed to self::find() and
   * self::replaceWith() are reset to their defaults.  However, messages
   * accumulate and the contents are maintained through every call.
   *
   * @return self
   *
   * @throws RuntimeException
   *   If the selected mode is not supported.
   *
   * @see self::reset()
   */
  public function redact(): self {
    $context = [
      'message' => $this->message,
      'pointer_regex' => $this->getPointerRegex(),
      'replacement' => $this->replacement,
    ];
    switch ($this->mode) {
      case ProcessorModes::YAML:
        $data = Yaml::parse($this->contents);
        $before = $data;
        $this->redactInArray($data, $context);
        if ($before !== $data) {
          $this->contents = Yaml::dump($data, 6, 2);
        }
        break;

      case ProcessorModes::PHP:
        $this->redactInPhp($this->contents, $context);
        break;

      case ProcessorModes::ENV:
        $this->redactInBash($this->contents, $context);
        break;
      case ProcessorModes::TXT:
        $this->redactInText($this->contents, $context);
        break;

      default:
        throw new RuntimeException(sprintf('Unsupported mode %s', $this->mode));
    }

    $this->message = $context['message'];
    $this->reset();

    return $this;
  }


  private function redactInArray(array &$data, array &$context) {
    $context += [
      'pointer' => [],
      'message' => '',
    ];
    foreach ($data as $k => $v) {
      $context['pointer'][] = $k;

      $pointer = implode('.', $context['pointer']);
      if ($this->shouldValueBeRedacted("$pointer.$k", $context['pointer_regex'])) {
        $data[$k] = $this->replacement;
        $context['message'] .= sprintf('%s%s has been redacted%s', self::ICON, $pointer, PHP_EOL);
      }
      if (is_array($data[$k])) {
        $this->redactInArray($data[$k], $context);
      }
      array_pop($context['pointer']);
    }
  }

  protected function shouldValueBeRedacted(string $pointer, array $regex): bool {
    foreach ($regex as $r) {
      if (preg_match('#' . $r . '#i', $pointer)) {
        return TRUE;
      }
    }

    return FALSE;
  }

  private function redactInPhp(string &$php_code, array &$context) {
    $context += ['message' => ''];
    $lexer = new RedactPasswordsInPhpLexer();
    $lexer->setInput($php_code);
    $lexer->moveNext();
    while (TRUE) {
      if (!$lexer->lookahead) {
        break;
      }
      $lexer->moveNext();
      $token = new TokenAdapter($lexer->token);
      if ($token->isA(RedactPasswordsInPhpLexer::T_VAR_ASSIGNMENT)) {
        $find = $token->getValue();
        preg_match('#' . RedactPasswordsInPhpLexer::REGEX_KEY . '#', $find, $matches);
        $pointer = $matches[1] ?? NULL;
        if (!$pointer || (!$this->shouldValueBeRedacted($pointer, $context['pointer_regex']))) {
          continue;
        }
        $replace = preg_replace('#(=>.+?)(\w+)#', '$1' . $this->replacement, $find);
        $php_code = str_replace($find, $replace, $php_code);
        $context['message'] .= sprintf('%s%s has been redacted%s', self::ICON, $pointer, PHP_EOL);
      }
    }
  }

  private function redactInText(string &$text, array &$context) {
    $context += ['message' => ''];
    foreach ($context['pointer_regex'] as $pointer_regex) {
      $count = 0;
      $text = preg_replace("#$pointer_regex#i", $context['replacement'], $text, 1, $count);
      if ($count > 0) {
        $context['message'] .= sprintf('%s%s has been redacted%s', self::ICON, $pointer_regex, PHP_EOL);
      }
    }
  }

  private function redactInBash(string &$bash_code, array &$context) {
    $context += ['message' => ''];
    $lexer = new RedactPasswordsInBashLexer();
    $lexer->setInput($bash_code);
    $lexer->moveNext();
    while (TRUE) {
      if (!$lexer->lookahead) {
        break;
      }
      $lexer->moveNext();
      $token = new TokenAdapter($lexer->token);
      $find = $token->getValue();
      preg_match('#' . RedactPasswordsInBashLexer::REGEX_KEY . '#', $find, $matches);
      $pointer = $matches[1] ?? NULL;
      if ($token->isA(RedactPasswordsInBashLexer::T_URL_ASSIGNMENT)) {
        list($pointer, $url) = explode('=', $find);
        if (!$pointer || (!$this->shouldValueBeRedacted($pointer, $context['pointer_regex']))) {
          continue;
        }
        $data = [$pointer => parse_url($url)];
        $before = $data;
        $url_context = ['message' => '', 'pointer_regex' => ["$pointer.pass"]];
        $this->redactInArray($data, $url_context);
        if ($before !== $data) {
          $replace = "$pointer=" . build_url($data[$pointer]);
          $bash_code = str_replace($find, $replace, $bash_code);
          $context['message'] .= $url_context['message'];
        }
      }
      elseif ($token->isA(RedactPasswordsInBashLexer::T_VAR_ASSIGNMENT)) {
        if (!$pointer || (!$this->shouldValueBeRedacted($pointer, $context['pointer_regex']))) {
          continue;
        }
        $replacement = $this->replacement;
        if ('' === $replacement) {
          $replacement = '""';
        }
        $replace = preg_replace('#([^=]+=)(.*)#', '$1' . $replacement, $find);
        $bash_code = str_replace($find, $replace, $bash_code);
        $context['message'] .= sprintf('%s%s has been redacted%s', self::ICON, $pointer, PHP_EOL);
      }
    }
  }

}
