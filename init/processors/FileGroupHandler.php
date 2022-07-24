<?php

use AKlump\LiveDevPorter\Processors\EnvTrait;
use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Processors\ProcessorSkippedException;
use AKlump\LiveDevPorter\Processors\YamlTrait;

/**
 * Rename/sanitize files as appropriate.
 */
final class FileGroupHandler extends ProcessorBase {

  use EnvTrait;
  use YamlTrait;

  /**
   * {@inheritdoc}
   */
  public function process() {
    if (!$this->shouldProcess()) {
      throw new ProcessorSkippedException();
    }

    $move_to = $this->getSourceBasedFilepath([
      'dev' => 'dev',
      'local' => 'dev',
      'live' => 'prod',
      'test' => 'staging',
    ]);
    $new_name_label = basename($move_to);

    $is_handled = FALSE;
    if ($this->shouldSanitize()) {
      switch ($this->getFileInfo()['basename']) {
        case 'website_backup.local.yml':
          $is_handled = TRUE;
          $response = [];
          foreach ([
                     'aws_access_key_id',
                     'aws_secret_access_key',
                   ] as $variable_name) {
            $this->yamlReplaceValue($variable_name);
            $response[] = $variable_name;
          }
          $this->yamlReplaceValue('database.password', ProcessorBase::TOKENS__PASSWORD);
          if ($this->saveFile($move_to) !== FALSE) {
            return sprintf("Removed %s from %s.", implode(', ', $response), $new_name_label);
          }
          break;

        case '.env':
          $is_handled = TRUE;
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
      }
    }

    if (!$is_handled && $this->saveFile($move_to) !== FALSE) {
      return sprintf("Saved %s", $new_name_label);
    }

    throw new ProcessorSkippedException();
  }

  /**
   * Should this processor been applied?
   *
   * @return bool
   *   True if this processor should be applied.
   */
  private function shouldProcess(): bool {
    return $this->isWriteableEnvironment() && in_array($this->filesGroupId, [
        'install',
        'secrets',
      ]) && $this->loadFile();
  }

  /**
   * @return bool
   *   True if the file should be sanitized.
   */
  private function shouldSanitize(): bool {
    return $this->filesGroupId === 'install';
  }
}
