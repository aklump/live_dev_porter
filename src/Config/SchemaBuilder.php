<?php

namespace AKlump\LiveDevPorter\Config;

/**
 * Adds config-derived attributes to the JSON schemas.
 */
final class SchemaBuilder {

  /**
   * @var array
   */
  private $config;

  /**
   * @var string
   */
  private $jsonSchemaSource;

  /**
   * @var string
   */
  private $jsonSchemaDist;

  public function __construct(array $config, array $cloudy_config) {
    $this->config = $cloudy_config;
    $this->jsonSchemaSource = __DIR__ . '/../../json_schema/config.schema.json';
    $this->jsonSchemaDist = $config['CACHE_DIR'] . '/config.schema.json';
  }

  public function destroy() {
    if (file_exists($this->jsonSchemaDist)) {
      unlink($this->jsonSchemaDist);
    }
  }

  public function build() {
    $parent_dir = dirname($this->jsonSchemaDist);
    if (!file_exists($parent_dir)) {
      $result = mkdir($parent_dir, 0755, TRUE);
      if (!$result) {
        throw new \RuntimeException(sprintf('Failed to create json schema distribution directory: %s', $parent_dir));
      }
    }
    $data = json_decode(file_get_contents($this->jsonSchemaSource), TRUE);
    if (!is_array($data) || empty($data)) {
      throw new \RuntimeException(sprintf('Failed to load json schema:  %s', $this->jsonSchemaSource));
    }

    // This step replaces our tokens with user-configured, realtime values.
    $this->populateEnum($data, [
      'DATABASE_IDS' => $this->getDatabaseIds(),
      'FILE_GROUP_IDS' => $this->getFileGroups(),
      'ENVIRONMENT_IDS' => $this->getEnvironmentIds(),
      'PLUGIN_IDS' => $this->getPluginIds(),
      'WORKFLOW_IDS' => $this->getWorkflowIds(),
    ]);

    file_put_contents($this->jsonSchemaDist, json_encode($data, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));

    return "JSON Schema has been rebuilt.";
  }

  private function populateEnum(&$value, array $context) {
    if (!is_array($value)) {
      return;
    }
    foreach (array_keys($value) as $k) {
      if ('enum' === $k && array_key_exists($value[$k][0], $context)) {
        $value[$k] = $context[$value[$k][0]];
      }
      else {
        $this->populateEnum($value[$k], $context);
      }
    }
  }

  private function getEnvironmentIds(): array {
    return array_keys($this->config['environments'] ?? []);
  }

  private function getPluginIds(): array {
    $directory = $this->config["__cloudy"]["ROOT"] . '/plugins';

    return array_values(array_filter(scandir($directory), function ($path) {
      return substr($path, 0, 1) !== '.';
    }));
  }

  private function getFileGroups(): array {
    return array_keys($this->config['file_groups'] ?? []);
  }

  private function getDatabaseIds(): array {
    $ids = [];
    foreach ($this->config['environments'] as $environment) {
      $ids = array_merge($ids, array_keys($environment['databases'] ?? []));
    }
    return array_unique($ids);
  }

  private function getWorkflowIds(): array {
    return array_keys($this->config['workflows'] ?? []);
  }

}
