<?php

namespace AKlump\LiveDevPorter\Config;

final class Validator {

  private $config;

  private $jsonSchema;

  public function __construct(array $config, RuntimeConfigInterface $cloudy_config) {
    $cloudy_config = $cloudy_config->all();
    $this->config = array_diff_key($cloudy_config, array_flip([

      // Remove known keys that are okay, but will invalidate the schema.
      '__cloudy',
      'additional_bootstrap',
      'additional_config',
      'author',
      'backup_remote_db_on_push',
      'bin',
      'commands',
      'compress_dumpfiles',
      'config_path_base',
      'default_command',
      'delete_pull_dumpfiles',
      'description',
      'max_database_rollbacks_to_keep',
      'name',
      'path_to_app',
      'plugins',
      'title',
      'version',
    ]));
    $this->jsonSchema = $config['CACHE_DIR'] . '/config.schema.json';
  }

  public function validate() {
    $js_like_array = function ($value, bool $init = NULL) use (&$js_like_array) {
      if (is_null($init)) {
        $init = TRUE;
        $value = json_decode(json_encode($value), TRUE);
      }
      if (is_scalar($value)) {
        return $value;
      }
      elseif (is_array($value)) {
        $keys = array_keys($value);
        if ($keys !== array_keys($keys)) {
          $value = (object) $value;
        }
      }
      if (is_iterable($value) || $value instanceof \stdClass) {
        foreach ($value as &$v) {
          $v = $js_like_array($v, $init);
        }
      }

      return $value;
    };

    $validator = new \JsonSchema\Validator();
    $to_validate = $js_like_array($this->config);
    $validator->validate($to_validate, (object) ['$ref' => 'file://' . $this->jsonSchema]);
    if (!$validator->isValid()) {
      $message = ['Invalid configuration:'];
      foreach ($validator->getErrors() as $error) {
        $message[] = sprintf("[%s] %s", $error['property'], $error['message']);
      }
      throw new \RuntimeException(implode(PHP_EOL, $message));
    }
  }

}
