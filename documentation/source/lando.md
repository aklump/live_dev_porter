# Lando

This article describes one way to use Live Dev Porter with Lando, which leverages the container so no host dependencies are required. You will need to use `lando ldp ...` when executing commands. In this example we're setting up a local environment called `dev` in the configuration.

## Base Path Must Be A Container Path

You must define _base_path_ using a container path, NOT a path on the host machine.

_.live_dev_porter/config.yml_ or _.live_dev_porter/config.local.yml_

```yaml
environments:
  dev:
    base_path: /app
    ...
```

## Correct Database Plugin

You must use the correct database plugin. Surprisingly, do not use one of the `lando*` database plugins, (which are only for running LDP _outside_ of the container). Instead use either the `env` or `mysql` database plugin:

_.live_dev_porter/config.yml_ or _.live_dev_porter/config.local.yml_

```yaml
environments:
  dev:
    ...
    databases:
      drupal:
        plugin: env
        path: .env
        var: DATABASE_URL
```

## Add Tooling

Add the following so that `lando ldp` can be used.

_.lando.yml_

```yaml
tooling:
  ldp:
    service: appserver
    description: Run Live Dev Porter from the container.
    cmd: "/app/vendor/bin/ldp"
    user: root
```
