#!/usr/bin/env php
<?php

/**
 * @file
 * Converts an .env database variable into JSON.
 *
 * The format is the same as for Lando.
 */

$path_to_env = $argv[1];
$database = $argv[2];

ob_start();
require_once $argv[1];
ob_end_clean();

$data = [
  [
    'external_connection' => [
      'host' => $databases['default']['default']['host'] ?? NULL,
      'port' => $databases['default']['default']['port'] ?? NULL,
    ],
    'creds' => [
      'database' => $databases['default']['default']['database'] ?? NULL,
      'user' => $databases['default']['default']['username'] ?? NULL,
      'password' => $databases['default']['default']['password'] ?? NULL,
    ],
  ],
];
echo json_encode($data);
