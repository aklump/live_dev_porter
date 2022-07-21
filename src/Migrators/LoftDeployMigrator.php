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

  const LOCAL = 'dev';

  const LOCAL_FILES = 'local';

  const REMOTE = 'live';

  public function __construct(string $loft_deploy_config_dir, array $initial_config) {
    $this->sourceDir = $loft_deploy_config_dir;
    $this->initialConfig = $initial_config;
  }

  public function getNewLocalConfig() {
    return [
      'local' => self::LOCAL,
      'remote' => self::REMOTE,
    ];
  }

  public function getNewConfig() {
    $loft_deploy_config = Yaml::parseFile($this->sourceDir . '/config.yml');
    $conf = function ($path) use ($loft_deploy_config) {
      return DotKey::on($loft_deploy_config)->get($path);
    };
    $init = function ($path) {
      return DotKey::on($this->initialConfig)->get($path);
    };
    $new_config = [];
    foreach ($this->map($conf, $init) as $key => $value) {
      if (is_callable($value)) {
        $value = $value($conf, $init);
      }
      $new_config = DotKey::on($new_config)->put($key, $value);
    }

    return $new_config;
  }

  private function map($conf, $init): array {
    return [
      'environments.' . self::LOCAL . '.label' => $conf('local.location'),
      'environments.' . self::LOCAL . '.write_access' => function ($conf) {
        return $conf('local.role') === 'dev';
      },
      'environments.' . self::LOCAL . '.plugin' => $init('environments.' . self::LOCAL . '.plugin'),
      'environments.' . self::LOCAL . '.base_path' => $init('environments.' . self::LOCAL . '.base_path'),
      'environments.' . self::LOCAL . '.command_workflows' => $init('environments.' . self::LOCAL . '.command_workflows') ?? [],
      'environments.' . self::LOCAL . '.databases' => function ($conf) {
        $databases = [];
        if ($conf('local.database')) {
          $database_id = $conf('local.database.name');
          if (strstr($database_id, 'drupal')) {
            $database_id = 'drupal';
          }
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
      'environments.' . self::LOCAL . '.files' => function ($conf) {
        $files = [];
        $items = $conf('local.copy_production_to') ?? [];
        foreach ($items as $item) {
          if (preg_match('/(install|secrets)\//', $item, $matches)) {
            $group_id = $matches[1];
            $files[$group_id] = dirname($item);
            if (strstr($files[$group_id], 'install/default/scaffold') === FALSE) {
              $files[$group_id] = str_replace('install/default', 'install/default/scaffold', $files[$group_id]);
            }
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
      'environments.' . self::LOCAL_FILES . '.label' => $conf('local.location'),
      'environments.' . self::LOCAL_FILES . '.write_access' => FALSE,
      'environments.' . self::LOCAL_FILES . '.plugin' => 'default',
      'environments.' . self::LOCAL_FILES . '.base_path' => './',
      'environments.' . self::LOCAL_FILES . '.files' => function ($conf) {
        $files = [];
        $items = $conf('local.copy_local_to') ?? [];
        foreach ($items as $item) {
          if (preg_match('/(install|secrets)\//', $item, $matches)) {
            $group_id = $matches[1];
            $files[$group_id] = './';
          }
        }

        return $files;
      },
      'environments.' . self::REMOTE . '.label' => 'TODO',
      'environments.' . self::REMOTE . '.write_access' => $init('environments.' . self::REMOTE . '.write_access'),
      'environments.' . self::REMOTE . '.plugin' => $init('environments.' . self::REMOTE . '.plugin'),
      'environments.' . self::REMOTE . '.base_path' => function ($conf) {
        return dirname($conf('production.config'));
      },
      'environments.' . self::REMOTE . '.ssh' => function ($conf) {
        return $conf('production.user') . '@' . $conf('production.host');
      },
      'environments.' . self::REMOTE . '.databases' => function ($conf) {
        $databases = [];
        if ($conf('local.database')) {
          $database_id = $conf('local.database.name');
          if (strstr($database_id, 'drupal')) {
            $database_id = 'drupal';
          }
          $databases[$database_id] = [
            'plugin' => 'env',
            'path' => '.env',
            'var' => 'DATABASE_URL',
          ];
        }

        return $databases;
      },
      'environments.' . self::REMOTE . '.files' => function ($conf) {
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
      'workflows' => function ($conf, $init) {
        return $init('workflows');
      },
      'workflows.develop' => function ($conf, $init) {
        $items = $init('workflows.develop') ?? [];
        $hooks = glob($this->sourceDir . '/hooks/*.sh');
        foreach ($hooks as $hook) {
          $items[] = [
            'processor' => basename($hook),
          ];
        }

        return $items;
      },
      'file_groups' => function ($conf) {
        $groups = [
          'install' => ['include' => ['/.live_dev_porter/config.local.yml']],
        ];
        foreach ([
                   'local.copy_local_to',
                   'local.copy_production_to',
                   'local.copy_staging_to',
                 ] as $key) {
          $items = $conf($key) ?? [];
          foreach ($items as $item) {
            if (!preg_match('/(install|secrets)\//', $item, $matches)) {
              continue;
            }
            $group_id = $matches[1];
            $include_path = preg_replace('/\.(dev|prod|staging)/', '', $item);
            switch ($group_id) {
              case 'install':
                list(, $include_path) = explode('install/default/', $include_path);
                if (preg_match('/(.+)(\.local\..+)/', $include_path, $m)) {
                  $include_path = '*' . $m[2];
                }
                break;
              case 'secrets':
                list(, $include_path) = explode('default/secrets/', $include_path);
                break;
            }
            $groups[$group_id]['include'] = $groups[$group_id]['include'] ?? [];
            $include_path = 'TODO' . ltrim($include_path, '/');
            if (!in_array($include_path, $groups[$group_id]['include'])) {
              $groups[$group_id]['include'][] = $include_path;
            }
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
