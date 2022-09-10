# Creating Scaffold Files from the Local Environment

> You want to copy un-versioned local files, e.g. _.htaccess, settings.local.php, .env_ to a source-controlled folder called _install/_, at the same time removing any secrets. You do this so that these files can be source-controlled and used in installation processes. These are sometimes called scaffold files.

This is how you do that.

1. Configure a second, local environment, e.g. `local`.
3. Set `write_access` to `false`.
2. Setup `files` as you would a normal remote, that is, with paths to the original files.
4. Do not define `databases` because this will ensure only files are pulled, even without using `pull -f`.
5. Now run `ldp pull local` to copy the files; notice how you specify the "remote" in the CLI argument.

_.live_dev_porter/config.yml_

```yaml
environments:
  dev:
    label: ITLS
    write_access: true
    plugin: default
    base_path: /alpha/bravo/app
    command_workflows:
      pull: develop
    databases:
      drupal:
        plugin: lando
        service: database
    files:
      install: install
      public: web/sites/default/files
      private: private/default/files
  local:
    label: ITLS
    write_access: false
    plugin: default
    base_path: /alpha/bravo/app
    files:
      install: ./
```
