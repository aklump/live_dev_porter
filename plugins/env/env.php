#!/usr/bin/env php
<?php

/**
 * @file
 * Converts an .env database variable into JSON.
 *
 * The format is the same as for Lando.
 */

$path_to_env = $argv[1];
$env_var = $argv[2];
$contents = file_get_contents($path_to_env);

preg_match('/' . preg_quote($env_var) . '=(.+)/', $contents, $matches);
if (empty($matches[1])) {
  echo "Missing environment variable: $env_var";
  exit(1);
}

$data = parse_url($matches[1]);

if (array_diff(['host', 'path', 'user', 'pass'], array_keys($data))) {
  echo "Incomplete environment variable: $env_var";
  exit(1);
}

$data = [
  [
    'protocol' => $data['protocol'] ?? 'tcp',
    'external_connection' => [
      'host' => $data['host'],
      'port' => $data['port'] ?? NULL,
    ],
    'creds' => [
      'database' => trim($data['path'], '/'),
      'user' => $data['user'],
      'password' => $data['pass'],
    ],
  ],
];
echo json_encode($data);
