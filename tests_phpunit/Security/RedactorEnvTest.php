<?php

namespace Security;

use AKlump\LiveDevPorter\Processors\ProcessorModes;
use AKlump\LiveDevPorter\Security\Redactor;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Security\Redactor::redactInBash
 * @covers \AKlump\LiveDevPorter\Security\Redactor::redact
 * @uses   \AKlump\LiveDevPorter\Security\Redactor
 * @uses   \AKlump\LiveDevPorter\Lexers\RedactPasswordsInBashLexer
 * @uses   \AKlump\LiveDevPorter\Lexers\TokenAdapter
 * @uses   \AKlump\LiveDevPorter\Processors\DetectProcessorMode
 */
class RedactorEnvTest extends TestCase {

  use TestWithFilesTrait;

  public function testCanRedactPasswordInUrlInEnv() {
    $filepath = $this->getTestFileFilepath('test.env');
    $contents = file_get_contents($filepath);

    $redactor = (new Redactor($contents, ProcessorModes::ENV));
    $messages = $redactor->find(['DATABASE_URL'])
      ->redact()
      ->getMessage();
    $replacement = $redactor->getReplacement();
    $this->assertStringContainsString(sprintf("DATABASE_URL=mysql://drupal8:%s@database/drupal8", $replacement), $contents);
    $this->assertStringNotContainsString('rock$ol1D', $contents);
    $this->assertSame(sprintf('DATABASE_URL.pass has been redacted%s', PHP_EOL), $messages);
  }

  public function testCanRedactWithEmptyStringInEnvFile() {
    $filepath = $this->getTestFileFilepath('test.env');
    $contents = file_get_contents($filepath);
    (new Redactor($contents, ProcessorModes::ENV))->replaceWith('')->redact();
    $this->assertStringContainsString('CLIENT_SECRET=""', $contents);
  }

  public function testCanRedactInEnvFile() {
    $filepath = $this->getTestFileFilepath('test.env');
    $contents = file_get_contents($filepath);

    $redactor = (new Redactor($contents, ProcessorModes::ENV));
    $message = $redactor->redact()->getMessage();
    $replacement = $redactor->getReplacement();
    $this->assertStringContainsString(sprintf("CLIENT_SECRET=%s", $replacement), $contents);
    $this->assertStringNotContainsString("TQiGdby59oBv3n\$BqOZVxzkKX9ojztZX1hIIK6jIKog\q>iN*IDCbO8b\$pbmT1BhMiijIHx4XchzwQ`zk55n24r$\ZQ1P.qkcqZcGEiW7J1-K0jcC9|HC(Csl<;kwxPteegp7aS4iNq~to", $contents);
    $this->assertStringContainsString('CLIENT_SECRET has been redacted', $message);
  }

  public function testCanRedactInEnvFileAutoMode() {
    $filepath = $this->getTestFileFilepath('test.env');
    $contents = file_get_contents($filepath);

    $redactor = (new Redactor($contents));
    $message = $redactor->redact()->getMessage();
    $replacement = $redactor->getReplacement();
    $this->assertStringContainsString(sprintf("CLIENT_SECRET=%s", $replacement), $contents);
    $this->assertStringNotContainsString("TQiGdby59oBv3n\$BqOZVxzkKX9ojztZX1hIIK6jIKog\q>iN*IDCbO8b\$pbmT1BhMiijIHx4XchzwQ`zk55n24r$\ZQ1P.qkcqZcGEiW7J1-K0jcC9|HC(Csl<;kwxPteegp7aS4iNq~to", $contents);
    $this->assertStringContainsString('CLIENT_SECRET has been redacted', $message);
  }

}
