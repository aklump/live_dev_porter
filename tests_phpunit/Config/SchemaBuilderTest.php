<?php

namespace AKlump\LiveDevPorter\Tests\Config;

use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;
use AKlump\LiveDevPorter\Config\SchemaBuilder;
use AKlump\LiveDevPorter\Tests\TestingTraits\TestWithFilesTrait;
use PHPUnit\Framework\TestCase;

define('ROOT', __DIR__ . '/../../');

/**
 * @covers \AKlump\LiveDevPorter\Config\SchemaBuilder
 */
class SchemaBuilderTest extends TestCase {

  use TestWithFilesTrait;

  public function testMissingEmptyPluginDirThrows() {
    $cloudy_config = $this->createMock(RuntimeConfigInterface::class);
    $builder = new SchemaBuilder([
      'ROOT' => ROOT,
      'CACHE_DIR' => $this->getTestFileFilepath('.cache/', TRUE),
      'PLUGINS_DIR' => '',
    ], $cloudy_config);
    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessageMatches('/PLUGINS_DIR/');
    $builder->onRebuildConfig();
  }

  public function testMissingPluginsDirThrows() {
    $cloudy_config = $this->createMock(RuntimeConfigInterface::class);
    $builder = new SchemaBuilder([
      'ROOT' => ROOT,
      'CACHE_DIR' => $this->getTestFileFilepath('.cache/', TRUE),
    ], $cloudy_config);
    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessageMatches('/PLUGINS_DIR/');
    $builder->onRebuildConfig();
  }


}
