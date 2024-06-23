<?php

namespace Processors;

use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Processors\YamlTrait;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Yaml\Yaml;

/**
 * @covers \AKlump\LiveDevPorter\Processors\YamlTrait
 * @uses   \AKlump\LiveDevPorter\Processors\ProcessorBase::__construct()
 * @uses   \AKlump\LiveDevPorter\Processors\ProcessorBase::loadFile()
 * @uses   \AKlump\LiveDevPorter\Processors\ProcessorBase::validateFileIsLoaded()
 */
final class YamlTraitTest extends TestCase {

  use TestWithFilesTrait;

  public function testYamlReplaceValueReturnsFalseWhenFileIsEmpty() {
    $filepath = $this->getTestFileFilepath('empty.yml');
    $this->assertEmpty(file_get_contents($filepath));
    $processor_config = [
      'FILEPATH' => $filepath,
    ];
    $obj = new YamlTraitTestable($processor_config);
    $result = $obj->_yamlReplaceValue('foo.bar', 'REDACTED');
    $this->assertFalse($result);
  }

  public function testYamlReplaceValueReturnsFalseOnNoChange() {
    $filepath = $this->getTestFileFilepath('config.local.prod.yml');
    $processor_config = [
      'FILEPATH' => $filepath,
    ];
    $obj = new YamlTraitTestable($processor_config);
    $result = $obj->_yamlReplaceValue('foo.bar', 'REDACTED');
    $this->assertFalse($result);
  }

  public function testYamlReplaceValueRedactsPassword() {
    $filepath = $this->getTestFileFilepath('config.local.prod.yml');
    $processor_config = [
      'FILEPATH' => $filepath,
    ];
    $obj = new YamlTraitTestable($processor_config);
    $result = $obj->_yamlReplaceValue('environments.live.databases.drupal.password', 'REDACTED');
    $this->assertTrue($result);
    $this->assertSame('REDACTED', $obj->getLoadedContentsAsArray()['environments']['live']['databases']['drupal']['password']);
  }
}

class YamlTraitTestable extends ProcessorBase {

  use YamlTrait;

  public function getLoadedContentsAsArray() {
    return Yaml::parse($this->loadedFile['contents']);
  }

  public function _yamlReplaceValue($variable_name, $replace_with = '') {
    $this->loadFile();

    return $this->yamlReplaceValue($variable_name, $replace_with);
  }
}
