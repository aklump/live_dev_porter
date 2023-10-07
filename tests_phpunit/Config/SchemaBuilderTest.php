<?php

namespace AKlump\LiveDevPorter\Tests\Config;

use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;
use AKlump\LiveDevPorter\Config\SchemaBuilder;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Config\SchemaBuilder
 */
class SchemaBuilderTest extends TestCase {

  use \AKlump\LiveDevPorter\Tests\TestHelpers\TestingFilesTrait;

  public function testMissingEmptyPluginDirThrows() {
    $cloudy_config = $this->createMock(RuntimeConfigInterface::class);
    $builder = new SchemaBuilder([
      'CACHE_DIR' => $this->getCacheDir(),
      'PLUGINS_DIR' => '',
    ], $cloudy_config);
    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessageMatches('/PLUGINS_DIR/');
    $builder->build();
  }

  public function testMissingPluginsDirThrows() {
    $cloudy_config = $this->createMock(RuntimeConfigInterface::class);
    $builder = new SchemaBuilder([
      'CACHE_DIR' => $this->getCacheDir(),
    ], $cloudy_config);
    $this->expectException(\RuntimeException::class);
    $this->expectExceptionMessageMatches('/PLUGINS_DIR/');
    $builder->build();
  }
}
