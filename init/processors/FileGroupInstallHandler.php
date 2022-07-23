<?php

use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Processors\ProcessorSkippedException;

/**
 * Remove secrets and passwords from install files.
 */
final class FileGroupInstallHandler extends ProcessorBase {

  /**
   * {@inheritdoc}
   */
  public function process() {
    if (!$this->isWriteableEnvironment() || 'install' !== $this->filesGroupId || !$this->loadFile()) {
      throw new ProcessorSkippedException();
    }
    $move_to = $this->getSourceBasedFilepath([
      'dev' => 'dev',
      'local' => 'dev',
      'live' => 'prod',
      'test' => 'staging',
    ]);
    $new_name_label = basename($move_to);

    switch ($this->getFileInfo()['basename']) {
      case 'website_backup.local.yml':
        $response = [];
        foreach ([
                   'aws_secret_access_key',
                   'database.password',
                 ] as $variable_name) {
          $this->yamlReplaceValue($variable_name);
          $response[] = $variable_name;
        }
        if ($this->saveFile($move_to) !== FALSE) {
          return sprintf("Removed %s from %s.", implode(', ', $response), $new_name_label);
        }
        break;

      case '.env':
        $response = [];
        foreach ([
                   'DATABASE_URL',
                 ] as $variable_name) {
          $this->envReplaceUrlPassword($variable_name);
          $response[] = $variable_name . ' password';
        }
        foreach ([
                   'HASH_SALT',
                 ] as $variable_name) {
          $this->envReplaceValue($variable_name);
          $response[] = $variable_name;
        }
        if ($this->saveFile($move_to) !== FALSE) {
          return sprintf("Removed %s from %s.", implode(', ', $response), $new_name_label);
        }
        break;

      case 'settings.local.php':
        $this->loadedFile['contents'] = preg_replace("/('password' => ')(.+)(')/", '$1PASSWORD$3', $this->loadedFile['contents']);
        $response[] = '$databases["default"]["default"]["password"]';
        if ($this->saveFile($move_to) !== FALSE) {
          return sprintf("Removed %s from %s.", implode(', ', $response), $new_name_label);
        }
        break;

      default:
        if ($this->saveFile($move_to) !== FALSE) {
          return sprintf("Saved %s", $new_name_label);
        }
        break;
    }

    throw new ProcessorSkippedException();
  }

}
