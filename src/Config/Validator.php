<?php

namespace AKlump\LiveDevPorter\Config;

final class Validator {

  private $config;

  private $jsonSchema;

  public function __construct(array $config, array $cloudy_config) {
    $this->config = array_diff_key($cloudy_config, array_flip([

      // Remove known keys that are okay, but will invalidate the schema.
      '__cloudy',
      'title',
      'name',
      'description',
      'version',
      'author',
      'config_path_base',
      'path_to_app',
      'additional_config',
      'additional_bootstrap',
      'default_command',
      'commands',
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
      if (is_iterable($value)) {
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
