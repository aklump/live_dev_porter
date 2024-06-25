<?php

namespace AKlump\LiveDevPorter\Tests\Processors;

use AKlump\LiveDevPorter\Processors\ProcessorModes;
use AKlump\LiveDevPorter\Processors\RedactPasswords;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;
use RuntimeException;
use Symfony\Component\Yaml\Yaml;

/**
 * @covers \AKlump\LiveDevPorter\Processors\RedactPasswords
 * @uses   \AKlump\LiveDevPorter\Lexers\TokenAdapter
 * @uses   \AKlump\LiveDevPorter\Lexers\RedactPasswordsInPhpLexer
 * @uses   \AKlump\LiveDevPorter\Lexers\RedactPasswordsInBashLexer
 */
class RedactPasswordsTest extends TestCase {

  use TestWithFilesTrait;

  public function testCanRedactPasswordInUrlInEnv() {
    $filepath = $this->getTestFileFilepath('test.env');
    $contents = file_get_contents($filepath);
    $message = (new RedactPasswords())(ProcessorModes::ENV, $contents, [
      'DATABASE_URL',
    ]);
    $this->assertStringContainsString(sprintf("DATABASE_URL=mysql://drupal8:%s@database/drupal8", RedactPasswords::DEFAULT_REPLACEMENT), $contents);
    $this->assertStringNotContainsString('rock$ol1D', $contents);
    $this->assertStringContainsString('DATABASE_URL has been redacted', $message);
  }

  public function testCanRedactInEnvFile() {
    $filepath = $this->getTestFileFilepath('test.env');
    $contents = file_get_contents($filepath);
    $message = (new RedactPasswords())(ProcessorModes::ENV, $contents, [
      'CLIENT_SECRET',
    ]);
    $this->assertStringContainsString(sprintf("CLIENT_SECRET=%s", RedactPasswords::DEFAULT_REPLACEMENT), $contents);
    $this->assertStringNotContainsString("TQiGdby59oBv3n\$BqOZVxzkKX9ojztZX1hIIK6jIKog\q>iN*IDCbO8b\$pbmT1BhMiijIHx4XchzwQ`zk55n24r$\ZQ1P.qkcqZcGEiW7J1-K0jcC9|HC(Csl<;kwxPteegp7aS4iNq~to", $contents);
    $this->assertStringContainsString('CLIENT_SECRET has been redacted', $message);
  }

  public function testCanRedactDatabasePasswordInSettingsPhp() {
    $filepath = $this->getTestFileFilepath('settings.php');
    $contents = file_get_contents($filepath);
    $message = (new RedactPasswords())(ProcessorModes::PHP, $contents);
    $this->assertStringContainsString(sprintf("'password' => '%s',", RedactPasswords::DEFAULT_REPLACEMENT), $contents);
    $this->assertStringNotContainsString("'password' => 'drupal9',", $contents);
    $this->assertStringContainsString('password has been redacted', $message);
  }

  public function testImplicitPointersWorkAsExpected() {
    $filepath = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($filepath);
    (new RedactPasswords())(ProcessorModes::YAML, $contents, [
      'lorem',
      'food.fruits.apple',
    ]);
    $data = Yaml::parse($contents);
    $this->assertSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['lorem']);
    $this->assertSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['food']['fruits']['apple']);
  }

  public function testReplacementIsConfigurable() {
    $filepath = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($filepath);
    (new RedactPasswords('removed'))(ProcessorModes::YAML, $contents);
    $data = Yaml::parse($contents);
    $this->assertSame('removed', $data['foo']['pass']);
  }

  public function testRecursivityWorksAsExpected() {
    $filepath = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($filepath);
    (new RedactPasswords())(ProcessorModes::YAML, $contents);
    $data = Yaml::parse($contents);
    $this->assertSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['foo']['pass']);
    $this->assertSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['foo']['bar']['password']);
    $this->assertSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['secret']);
    $this->assertSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['private_key']);
    $this->assertSame('ipsum', $data['lorem']);
    $this->assertSame('sit', $data['foo']['bar']['dolar']);
  }

  public function testSettingReplaceableKeysToEmptyArraysDisablesDefaultKeys() {
    $filepath = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($filepath);
    (new RedactPasswords(NULL, []))(ProcessorModes::YAML, $contents);
    $data = Yaml::parse($contents);
    $this->assertNotSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['foo']['pass']);
    $this->assertNotSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['foo']['bar']['password']);
    $this->assertNotSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['secret']);
    $this->assertNotSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['private_key']);
  }

  public function testPasswordIsRedactedInLDPConfigYAML() {
    $filepath = $this->getTestFileFilepath('config.local.prod.yml');
    $contents = file_get_contents($filepath);
    $result = (new RedactPasswords())(ProcessorModes::YAML, $contents);
    $this->assertStringContainsString('environments.live.databases.drupal', $result);
    $data = Yaml::parse($contents);
    $this->assertSame(RedactPasswords::DEFAULT_REPLACEMENT, $data['environments']['live']['databases']['drupal']['password']);
  }

  public function testUnsupportedFileTypeThrows() {
    $this->expectException(RuntimeException::class);
    $contents = '';
    (new RedactPasswords())(-1, $contents);
  }

}
