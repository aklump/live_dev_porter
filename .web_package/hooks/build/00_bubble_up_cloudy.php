<?php
/**
 * @file
 * Merge Cloudy's composer.json into Live Dev Porter's composer.json.
 */

use AKlump\WebPackage\BuildFailException;

$build
  ->loadFile($argv[7] . '/cloudy/composer.json', function ($json) use (&$require) {
    $data = json_decode($json, TRUE);
    $require = $data['require'] ?? [];

    return $json;
  })
  ->loadFile($argv[7] . '/composer.json', function ($json) use ($require) {
    $data = json_decode($json, TRUE);

    foreach ($require as $package => $constraint) {
      if (isset($data['require'][$package]) && $data['require'][$package] !== $constraint) {
        throw new BuildFailException("Cloudy dependency conflict with app dependency: $package");
      }
    }

    $data['require'] = $data['require'] ?? [];
    $data['require'] += $require;

    return json_encode($data, JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT);
  })
  ->saveReplacingSourceFile();
