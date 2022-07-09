<?php

namespace AKlump\LiveDevPorter\Config;

/**
 * Adds config-derived attributes to the JSON schemas.
 */
final class SchemaBuilder {

  private $plugins;

  private $config;

  private $jsonSchemaSource;

  private $jsonSchemaDist;

  public function __construct(array $config) {
    $this->config = $config;
    $this->jsonSchemaSource = __DIR__ . '/../../json_schema';
    $this->jsonSchemaDist = $config['CACHE_DIR'];
  }

  public function build() {
    if (!file_exists($this->jsonSchemaDist)) {
      $result = mkdir($this->jsonSchemaDist, 0755, TRUE);
      if (!$result) {
        throw new \RuntimeException(sprintf('Failed to create json schema distribution directory: %s', $this->jsonSchemaDist));
      }
    }
    $path = '/config.schema.json';
    $data = json_decode(file_get_contents($this->jsonSchemaSource . $path), TRUE);
    $data['properties']['fetch_environment']['enum'] = $this->getEnvironmentIds();

    $data['properties']['environment']['enum'] = $this->getEnvironmentIds();

    $data['properties']['environments']['items']['properties']['plugin']['enum'] = $this->getPluginIds();
    $data['properties']['environments']['items']['properties']['files']['propertyNames']['enum'] = $this->getFileGroups();
    $data['properties']['environments']['items']['properties']['databases']['propertyNames']['enum'] = $this->getDatabaseIds();
    $this->removeEmptyEnum($data);

    file_put_contents($this->jsonSchemaDist . $path, json_encode($data, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));

    return "JSON Schema has been rebuilt.";
  }

  private function removeEmptyEnum(&$value) {
    if (!is_array($value)) {
      return;
    }
    foreach (array_keys($value) as $k) {
      if ('enum' === $k && empty($value[$k])) {
        unset($value[$k]);
      }
      else {
        $this->removeEmptyEnum($value[$k]);
      }
    }
  }

  private function getEnvironmentIds(): array {
    return array_filter(array_map(function ($data) {
      return $data['id'] ?? NULL;
    }, $this->config['environments'] ?? []));
  }

  private function getPluginIds(): array {
    if (empty($this->plugins)) {
      $directory = $this->config["__cloudy"]["ROOT"] . '/plugins';
      $this->plugins = array_values(array_filter(scandir($directory), function ($path) {
        return substr($path, 0, 1) !== '.';
      }));
    }

    return $this->plugins;
  }

  private function getFileGroups(): array {
    return array_filter(array_map(function ($data) {
      return $data['id'] ?? NULL;
    }, $this->config['file_groups'] ?? []));
  }

  private function getDatabaseIds(): array {
    return array_filter(array_map(function ($data) {
      return $data['id'] ?? NULL;
    }, $this->config['databases'] ?? []));
  }
}