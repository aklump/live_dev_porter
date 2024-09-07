<?php

namespace Security;

use AKlump\LiveDevPorter\Processors\ProcessorModes;
use AKlump\LiveDevPorter\Security\Redactor;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Yaml\Yaml;

/**
 * @covers \AKlump\LiveDevPorter\Security\Redactor
 * @uses   \AKlump\LiveDevPorter\Processors\DetectProcessorMode
 */
class RedactorYamlTest extends TestCase {

  use TestWithFilesTrait;

  public function testBareBonesWithDefaults() {
    $path = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($path);

    $redactor = new Redactor($contents, ProcessorModes::YAML);
    $redactor->redact();

    $data = Yaml::parse($contents);
    $replacement = $redactor->getReplacement();
    $this->assertSame($replacement, $data['foo']['pass']);
    $this->assertSame($replacement, $data['foo']['bar']['password']);
    $this->assertSame($replacement, $data['secret']);
    $this->assertSame($replacement, $data['private_key']);
  }

  public function testBareBonesWithDefaultsAutoMode() {
    $path = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($path);

    $redactor = new Redactor($contents);
    $redactor->redact();

    $data = Yaml::parse($contents);
    $replacement = $redactor->getReplacement();
    $this->assertSame($replacement, $data['foo']['pass']);
    $this->assertSame($replacement, $data['foo']['bar']['password']);
    $this->assertSame($replacement, $data['secret']);
    $this->assertSame($replacement, $data['private_key']);
  }

  public function testCustomPointerWorksAsExpected() {
    $path = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($path);

    $redactor = new Redactor($contents, ProcessorModes::YAML);
    $redactor->find(['secret'])->redact();

    $data = Yaml::parse($contents);
    $this->assertSame('EHje89ZJzgvOO3o1zPhd', $data['foo']['bar']['password']);
    $this->assertSame('REDACTED', $data['secret']);
  }

  public function testCustomReplacementWorksAsExpected() {
    $path = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($path);

    $redactor = new Redactor($contents, ProcessorModes::YAML);
    $redactor->find(['pass'])->replaceWith('PASSWORD')->redact();

    $data = Yaml::parse($contents);
    $this->assertSame('PASSWORD', $data['foo']['bar']['password']);
    $this->assertSame('PASSWORD', $data['foo']['pass']);
    $this->assertSame('sI1iFYRL9Bc4FHP5D0n91', $data['secret']);
  }

  public function testGetMessagesWorksAsExpected() {
    $path = $this->getTestFileFilepath('redact_passwords.yml');
    $contents = file_get_contents($path);

    $redactor = new Redactor($contents, ProcessorModes::YAML);
    $redactor->find(['\.?pass$'])->replaceWith('PASSWORD')->redact();
    $redactor->find(['secret'])->redact();

    $data = Yaml::parse($contents);
    $this->assertSame('PASSWORD', $data['foo']['pass']);
    $this->assertSame('EHje89ZJzgvOO3o1zPhd', $data['foo']['bar']['password']);
    $this->assertSame('REDACTED', $data['secret']);

    $message = $redactor->getMessage();
    $this->assertStringContainsString('foo.pass has been redacted', $message);
    $this->assertStringContainsString('secret has been redacted', $message);
  }

}
