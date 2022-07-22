# Drupal Plugin

* Provides database credentials from a Drupal settings.php file.

## Database Configuration

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: drupal
        settings: web/sites/default/settings.php
```

### Non-standard Database

_.live_dev_porter/config.yml_

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: drupal
        settings: web/sites/default/settings.php
        database: some_alt_db
```

* You may omit `database` if using the `default` value as shown above.

_web/sites/default/settings.php_

```php
$databases['default']['some_alt_db'] = [
  'driver' => 'mysql',
  'host' => 'database',
  'database' => 'drupal8',
  'username' => 'drupal8',
  'password' => 'drupal8',
  'prefix' => '',
];
```
