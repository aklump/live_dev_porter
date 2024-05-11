<?php

namespace AKlump\LiveDevPorter\Processors;

use AKlump\LiveDevPorter\Processors\EnvTrait;
use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Processors\ProcessorSkippedException;
use AKlump\LiveDevPorter\Processors\YamlTrait;

/**
 * Remove secrets and passwords from install files.
 */
final class FileGroupInstallHandler extends ProcessorBase {

  use EnvTrait;
  use YamlTrait;
  use PhpTrait;

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
      case 'settings.local.php':
        try {
          $this->phpReplaceValue('databases.default.default.password', 'PASSWORD');
        }
        catch (\Exception $exception) {
          // Not all environments have the password.
        }
        if ($this->saveFile($move_to) !== FALSE) {
          return sprintf("Removed password from %s", $new_name_label);
        }
        break;

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
                   'DATABASE_URL__DEVELOP',
                 ] as $variable_name) {
          $this->envReplaceUrlPassword($variable_name);
          $response[] = $variable_name . ' password';
        }
        foreach ([
                   'FACEBOOK_APP_SECRET',
                   'HASH_SALT',
                   'MAILCHIMP_API_KEY',
                   'MAILCHIMP_WEBHOOK_HASH',
                   'VIMEO_ACCESS_TOKEN',
                   'VIMEO_CLIENT_SECRET',
                   'GOOGLE_MAP_API_KEY',
                   'CLEANTALK_BLACKLIST_API_KEY',
                 ] as $variable_name) {
          $this->envReplaceValue($variable_name);
          $response[] = $variable_name;
        }
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
