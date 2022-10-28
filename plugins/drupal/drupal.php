#!/usr/bin/env php
<?php

/**
 * @file
 * Converts an .env database variable into JSON.
 *
 * The format is the same as for Lando.
 */

$settings_path = $argv[1];
$drupal_db_key = $argv[2];

// All sorts of things can go wrong when trying to include the settings.php
// file, so we are going to trap everything.
set_error_handler(function ($code, $message, $file) use (&$errors) {
  $errors[] = [$message, $file];
});
set_exception_handler(function ($exception) use (&$errors) {
  $errors[] = [$exception->getMessage(), $exception->getFile()];
});
ob_start();
require_once $settings_path;
ob_end_clean();
restore_error_handler();
restore_exception_handler();

$data = [
  [
    'external_connection' => [
      'host' => $databases[$drupal_db_key]['default']['host'] ?? NULL,
      'port' => $databases[$drupal_db_key]['default']['port'] ?? NULL,
    ],
    'creds' => [
      'database' => $databases[$drupal_db_key]['default']['database'] ?? NULL,
      'user' => $databases[$drupal_db_key]['default']['username'] ?? NULL,
      'password' => $databases[$drupal_db_key]['default']['password'] ?? NULL,
    ],
  ],
];
echo json_encode($data);
