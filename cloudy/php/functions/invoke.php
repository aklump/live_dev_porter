<?php
/* SPDX-License-Identifier: BSD-3-Clause */

/**
 * @file
 * Return a configuration value by key.
 */

use AKlump\LoftLib\Bash\Configuration;

$args = $argv;
array_shift($args);
$function = array_shift($args);

if (!function_exists($function)) {
  fail_because('Function does not exist: ' . $function);
  exit_with_failure();
}

if ($function == 'array_sort_by_item_length') {
  $var_name = array_shift($args);
}

$result = call_user_func_array($function, $args);

if (is_array($result)) {
  $var_service = new Configuration('cloudy_config');
  $eval_code = $var_service->getVarEvalCode($var_name, $result);
  echo $eval_code;
}
else {
  echo $result;
}
