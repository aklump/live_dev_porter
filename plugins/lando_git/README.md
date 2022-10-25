# Lando Plugin

* Provides database credentials from the Lando configuration basing the service on the current git branch.

## Database Configuration

```yaml
environments:
  foo:
    databases:
      bar:
        plugin: lando_git
        service_by_branch:
          master: database
          develop: database--develop
```
