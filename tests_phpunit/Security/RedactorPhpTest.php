<?php

namespace Security;

use AKlump\LiveDevPorter\Processors\ProcessorModes;
use AKlump\LiveDevPorter\Security\Redactor;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Security\Redactor::redactInPhp
 * @covers \AKlump\LiveDevPorter\Security\Redactor::redact
 * @uses   \AKlump\LiveDevPorter\Security\Redactor
 * @uses   \AKlump\LiveDevPorter\Lexers\RedactPasswordsInPhpLexer
 * @uses   \AKlump\LiveDevPorter\Lexers\TokenAdapter
 * @uses \AKlump\LiveDevPorter\Processors\DetectProcessorMode
 */
class RedactorPhpTest extends TestCase {

  use TestWithFilesTrait;

  public function testCanRedactDatabasePasswordInSettingsPhp() {
    $filepath = $this->getTestFileFilepath('settings.php');
    $contents = file_get_contents($filepath);
    $redactor = (new Redactor($contents, ProcessorModes::PHP))->redact();
    $messages = $redactor->getMessage();
    $this->assertStringContainsString(sprintf("'password' => '%s',", $redactor->getReplacement()), $contents);
    $this->assertStringNotContainsString("'password' => 'drupal9',", $contents);
    $this->assertStringContainsString(sprintf('password has been redacted%s', PHP_EOL), $messages);
  }

  public function testCanRedactDatabasePasswordInSettingsPhpAutoMode() {
    $filepath = $this->getTestFileFilepath('settings.php');
    $contents = file_get_contents($filepath);
    $redactor = (new Redactor($contents))->redact();
    $messages = $redactor->getMessage();
    $this->assertStringContainsString(sprintf("'password' => '%s',", $redactor->getReplacement()), $contents);
    $this->assertStringNotContainsString("'password' => 'drupal9',", $contents);
    $this->assertStringContainsString(sprintf('password has been redacted%s', PHP_EOL), $messages);
  }

}
