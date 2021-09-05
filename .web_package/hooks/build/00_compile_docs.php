<?php

/**
 * @file
 * Generates documentation, adjusts paths and adds to SCM.
 *
 * @see \AKlump\WebPackage\HookService
 */

namespace AKlump\WebPackage;

$build
  ->setDocumentationSource('documentation')
  ->generateDocumentationTo('docs')
  // This will adjust the path to the image, pulling it from docs.
  ->loadFile('README.md')
  ->replaceTokens([
    'images/live-dev-porter' => 'docs/images/live-dev-porter',
  ])
  ->saveReplacingSourceFile()
  ->displayMessages();
