<?php

/** @var string $command */
/** @var string $book_path */
/** @var \Symfony\Component\EventDispatcher\EventDispatcher $dispatcher */

use AKlump\Knowledge\Events\GetVariables;
use Symfony\Component\Yaml\Yaml;

$dispatcher->addListener(GetVariables::NAME, function (GetVariables $event) {
  $version_file = $event->getPathToSource() . '/../live_dev_porter.core.yml';
  $info = Yaml::parseFile($version_file);
  $event->setVariable('version', $info['version'] ?? NULL);
});
