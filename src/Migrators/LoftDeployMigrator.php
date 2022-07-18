<?php

namespace AKlump\LiveDevPorter\Migrators;

use Jasny\DotKey;
use Symfony\Component\Yaml\Yaml;

/**
 * Migrate from Loft Deploy to Live Dev Porter
 *
 * @todo Handle local.copy_local_to
 * @todo Handle local.copy_staging_to
 */
class LoftDeployMigrator {

  public function __construct(string $loft_deploy_config_dir) {
    $this->sourceDir = $loft_deploy_config_dir;
  }

  public function getNewLocalConfig() {
    return [
      'local' => 'local',
      'remote' => 'live',
    ];
  }

  public function getNewConfig() {
    $loft_deploy_config = Yaml::parseFile($this->sourceDir . '/config.yml');
    $conf = function ($path) use ($loft_deploy_config) {
      return DotKey::on($loft_deploy_config)->get($path);
    };
    $new_config = [];
    foreach ($this->map($conf) as $key => $value) {
      if (is_callable($value)) {
        $value = $value($conf);
      }
      $new_config = DotKey::on($new_config)->put($key, $value);
    }

    return $new_config;
  }

  private function map($conf): array {
    return [
      'environments.local.label' => $conf('local.location'),
      'environments.local.write_access' => function ($conf) {
        return $conf('local.role') === 'dev';
      },
      'environments.local.plugin' => 'default',
      'environments.local.base_path' => './',
      //      'environments.local.base_path' => $conf('local.basepath'),
      'environments.local.command_workflows' => [
        'pull' => 'develop',
        'export' => 'archive',
      ],
      'environments.local.databases' => function ($conf) {
        $databases = [];
        if ($conf('local.database')) {
          $database_id = $conf('local.drupal.root') ? 'drupal' : 'default';
          $databases[$database_id]['plugin'] = $conf('local.database.lando') ? 'lando' : 'mysql';
          if ($databases[$database_id]['plugin'] === 'lando') {
            $databases[$database_id] += [
              'service' => 'database',
            ];
          }
          else {
            $databases[$database_id] += [
              'host' => '',
              'port' => '',
              'name' => '',
              'password' => '',
              'user' => '',
            ];
          }
        }

        return $databases;
      },
      'environments.local.files' => function ($conf) {
        $files = [];
        $items = $conf('local.copy_production_to') ?? [];
        foreach ($items as $item) {
          if (preg_match('/(install|secrets)\//', $item, $matches)) {
            $group_id = $matches[1];
            $files[$group_id] = dirname($item);
          }
        }

        $items = $conf('local.files') ?? [];
        foreach ($items as $item) {
          if (strstr($item, 'private/') !== FALSE) {
            $files['private'] = $item;
          }
          else {
            $files['public'] = $item;
          }
        }

        return $files;
      },
      'environments.live.label' => '@todo',
      'environments.live.write_access' => FALSE,
      'environments.live.plugin' => 'default',
      'environments.live.base_path' => function ($conf) {
        return dirname($conf('production.config'));
      },
      'environments.live.ssh' => function ($conf) {
        return $conf('production.user') . '@' . $conf('production.host');
      },
      'environments.live.files' => function ($conf) {
        $files = [];
        $items = $conf('local.copy_production_to') ?? [];
        foreach ($items as $item) {
          if (preg_match('/(install|secrets)\//', $item, $matches)) {
            $group_id = $matches[1];
            $files[$group_id] = './';
          }
        }

        $items = $conf('local.files') ?? [];
        foreach ($items as $item) {
          if (strstr($item, 'private/') !== FALSE) {
            $files['private'] = $item;
          }
          else {
            $files['public'] = $item;
          }
        }

        return $files;
      },
      'workflows.archive' => function ($conf) {
        $has_drupal = $conf('local.drupal.root');
        if (!$has_drupal) {
          return [];
        }

        return [
          [
            'database' => 'drupal',
            'exclude_table_data' => [
              'cache*',
            ],
          ],
        ];
      },
      'workflows.develop' => function ($conf) {
        $has_drupal = $conf('local.drupal.root');
        if (!$has_drupal) {
          return [];
        }

        $items = [
          [
            'database' => 'drupal',
            'exclude_table_data' => [
              'cache*',
              'batch',
              'config_import',
              'config',
              'config_snapshot',
              'key_value_expire',
              'sessions',
              'watchdog',
            ],
          ],
        ];

        $hooks = glob($this->sourceDir . '/hooks/*.sh');
        foreach ($hooks as $hook) {
          $items[] = [
            'processor' => basename($hook),
          ];
        }

        return $items;
      },
      'file_groups' => function ($conf) {
        $groups = [];
        $copy_source = $conf('local.copy_source') ?? [];
        $items = $conf('local.copy_production_to') ?? [];
        foreach ($items as $delta => $item) {
          if (preg_match('/(install|secrets)\//', $item, $matches)) {
            $group_id = $matches[1];
            $value = $copy_source[$delta];
            $groups[$group_id]['include'][] = '/' . ltrim($value, '/');
          }
        }

        $items = $conf('local.files') ?? [];
        foreach ($items as $delta => $item) {
          $group_id = 'public';
          if (strstr($item, 'private/') !== FALSE) {
            $group_id = 'private';
          }

          $groups[$group_id] = [];
          $files = $this->getExcludeFiles($delta);
          if ($files) {
            $groups[$group_id]['exclude'] = $files;
          }
        }

        return $groups;
      },
      'bin' => $conf('bin'),
    ];
  }

  private function getExcludeFiles(int $old_group_id) {
    $filepath = $this->sourceDir . '/files' . ($old_group_id > 0 ? $old_group_id + 1 : '') . '_exclude.txt';

    $files = [];
    if (file_exists($filepath)) {
      $files = array_map(function ($path) {
        $path = rtrim($path);
        $path = '/' . ltrim($path, '/');
        if (!pathinfo($path, PATHINFO_EXTENSION)) {
          $path = rtrim($path, '/') . '/';
        }

        return $path;
      }, file($filepath));
    }
    $files[] = '/tmp/';
    $files = array_unique($files);
    sort($files);

    return $files;
  }
}
