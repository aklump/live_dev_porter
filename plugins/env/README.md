# Env Plugin

* Provides database credentials from a dot env file.

## Database Configuration

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: env
        path: .env
        var: DATABASE_URL
```
