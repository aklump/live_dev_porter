# Env Plugin

* Provides database credentials from a dot env file.
* `path` The relative path to the environment file to read.
* `var` The name of the environment variable that contains the database credentials. It must use this form: `mysql://USER:PASS@HOST/DATABASE`

## Database Configuration

_config.yml_

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: env
        path: .env
        var: DATABASE_URL
```

_.env_

```shell
DATABASE_URL=mysql://drupal9:drupal9@database/drupal9

```
