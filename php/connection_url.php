<?php
/**
 * @file
 *
 * Convert a .cnf filepath to a connection URL.
 */

$cnf = file_get_contents($argv[1]);
preg_match_all("/^(.+)=(.+)$/m", $cnf, $matches);
$values = array_map(function ($value) {
  return trim($value, '"');
}, $matches[2]);
$creds = array_combine($matches[1], $values);
$url = sprintf('mysql://%s:%s@%s', $creds['user'], 'PASSWORD', $creds['host']);
if (!empty($creds['port'])) {
  $url .= ':' . $creds['port'];
}
$url .= '/';
echo $url;
