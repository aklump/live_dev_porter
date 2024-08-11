<?php
/* SPDX-License-Identifier: BSD-3-Clause */

/**
 * @file
 * Validate a value against a schema.
 *
 * @see https://json-schema.org/latest/json-schema-validation.html
 */

use AKlump\LoftLib\Bash\Configuration;
use JsonSchema\Validator;

/** @var array $CLOUDY_FAILURES */
/** @var array $CLOUDY_SUCCESSES */
/** @var integer $CLOUDY_EXIT_STATUS */
/** @var string $CLOUDY_BASEPATH */
/** @var string $CLOUDY_CACHE_DIR */
/** @var string $CLOUDY_COMPOSER_VENDOR */
/** @var string $CLOUDY_CONFIG_JSON */
/** @var string $CLOUDY_CORE_DIR */
/** @var string $CLOUDY_PACKAGE_CONFIG */
/** @var string $CLOUDY_PACKAGE_CONTROLLER */
/** @var string $CLOUDY_RUNTIME_ENV */
/** @var string $CLOUDY_RUNTIME_UUID */
/** @var string $CLOUDY_START_DIR */
/** @var string $PHP_FILE_RUN_CONTROLLER */

$config_key = $argv[1] ?? NULL;
$name = $argv[2] ?? NULL;
$value = $argv[3] ?? NULL;

$config = json_decode($CLOUDY_CONFIG_JSON, TRUE);

$schema = \Jasny\DotKey::on($config)->get($config_key);
if (empty($schema)) {
  return;
}

// Handle casting 'true' 'false' in bash to boolean in PHP.
if ('boolean' === ($schema['type'] ?? '')) {
  $value = $value === 'true' ? TRUE : $value;
  $value = $value === 'false' ? FALSE : $value;
}

$validator = new Validator();
$validator->validate($value, (object) $schema);
if ($validator->isValid()) {
  return;
}

foreach ($validator->getErrors() as $error) {

  // Translate some default errors to our context.
  if ($error['message'] == 'String value found, but a boolean is required') {
    $error['message'] = 'Boolean options may not be given a value.';
  }

  fail_because(sprintf("[%s] %s", $name, $error['message']));
}
