<?php

namespace AKlump\LiveDevPorter\Config;

final class Validator {

  private static $mustValidate;

  private $config;

  private $jsonSchema;

  public function __construct(array $config) {
    $this->config = array_intersect_key($config, array_flip([
      'environment_roles',
      'environments',
      'file_groups',
      'databases',
    ]));
    $this->jsonSchema = __DIR__ . '/../../json_schema/dist';
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
      foreach ($value as &$v) {
        $v = $js_like_array($v, $init);
      }

      return $value;
    };
    $path_to_schema = $this->jsonSchema . '/config.schema.json';
    $validator = new \JsonSchema\Validator();
    $to_validate = $js_like_array($this->config);
    $validator->validate($to_validate, (object) ['$ref' => 'file://' . $path_to_schema]);
    if (!$validator->isValid()) {
      $message = ['Invalid configuration:'];
      foreach ($validator->getErrors() as $error) {
        $message[] = sprintf("[%s] %s", $error['property'], $error['message']);
      }
      throw new \RuntimeException(implode(PHP_EOL, $message));
    }
  }

}
