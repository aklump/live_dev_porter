# MySQL Plugin

> There is a bug in this plugin related to cloudy not merging the config correctly, and option A does not work Jul 19, 2022, aklump.

* Provide hard-coded database credentials
* Be careful with the password, notice it gets added to _config.local.yml_!
* [About protocols](https://dev.mysql.com/doc/refman/8.0/en/connection-options.html#option_general_protocol)

## Database Configuration

_.live_dev_porter/config.yml_

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: mysql
        protocol: TCP
        host: <HOST>
        port: <PORT>
        database: <NAME>
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
        protocol: TCP
        host: <HOST>
        port: <PORT>
        database: <NAME>
        user: <USER>
        password: <PASSWORD>
```
