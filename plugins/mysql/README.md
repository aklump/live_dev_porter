# MySQL Plugin

* Provide hard-coded database credentials
* Be careful with the password, notice it gets added to _config.local.yml_!

## Database Configuration

_.live_dev_porter/config.yml_

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: mysql
        host: <HOST>
        port: <PORT>
        name: <NAME>
        user: <USER>
```

_.live_dev_porter/config.local.yml_

```yaml
environments:
  foo:
    databases:
      bar:
        password: <PASSWORD>
```

### Option B

In this example, all configuration is moved to _config.local.yml_, which may be appropriate if the `foo` environment is shared across teams.

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: mysql
```

_.live_dev_porter/config.local.yml_

```yaml
environments:
  foo:
    databases:
      bar:
        host: <HOST>
        port: <PORT>
        name: <NAME>
        user: <USER>
        password: <PASSWORD>
```
