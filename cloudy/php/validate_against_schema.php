<?php

/**
 * @file
 * Validate a value against a schema.
 *
 * @see https://json-schema.org/latest/json-schema-validation.html
 */

use AKlump\LoftLib\Bash\Configuration;
use JsonSchema\Validator;

require_once __DIR__ . '/bootstrap.php';

$config = json_decode(isset($argv[1]) ? $argv[1] : '[]', true);
$config_key = isset($argv[2]) ? $argv[2] : null;
$name = isset($argv[3]) ? $argv[3] : null;
$value = isset($argv[4]) ? $argv[4] : null;
$schema = isset($config[$config_key]) ? $config[$config_key] : [];

// Handle casting 'true' 'false' in bash to boolean in PHP.
if ('boolean' === (isset($schema['type']) ? $schema['type'] : '')) {
  $value = $value === 'true' ? TRUE : $value;
  $value = $value === 'false' ? FALSE : $value;
}

$validator = new Validator();
$validator->validate($value, (object) $schema);
$exit_code = 0;

if (!$validator->isValid()) {
  $errors = [];
  $exit_code = 1;
  foreach ($validator->getErrors() as $error) {

    // Translate some default errors to our context.
    switch ($error['message']) {
      case 'String value found, but a boolean is required':
        $error['message'] = 'Boolean options may not be given a value.';
        break;
    }

    $errors[] = sprintf("[%s] %s", $name, $error['message']);
  }
  echo 'declare -a schema_errors=("' . implode('" "', $errors) . '")';
}

exit($exit_code);
