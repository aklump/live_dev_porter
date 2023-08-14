<!--
id: databases
tags: ''
-->

# Databases

If a project uses at least one database, it must be defined in configuration. You must give it an ID. Using that ID, it can be referenced in other parts of the configuration. You may define multiple databases if that applies to your situation.

You must also define which plugin is used to access your database, along with the plugin-specifiy configuation. Example plugins are: _mysql_, _env_, _lando_, _lando_git_.

If you have more than one database defined, the first listed in the configuration will be assumed unless you specify otherwise with `--database=ID`. In the following configuration example, `primary` will be assumed the default database.

```yaml
environments:
  -
    id: local
    databases:
      primary:
        plugin: lando
        service: database
      secondary:
        plugin: lando
        service: alt_database
```

## Excluding Tables or Data for Different Commands

You can omit entire tables using `exclude_tables`.

You may want to omit data from certain tables, such as in the case of cache tables. This is the reason for `exclude_table_data`. List one or more tables (astrix globbing allowed), whose _structure only_ should be copied.

Create one or more workflows with your table/data exclusion rules. Then use those workflows as command arguments.

```yaml
workflows:
  development:
    -
      database: drupal
      exclude_table_data:
        - cache*
        - batch
```

To export only table structure and no data from any table, do like this:

```yaml
workflows:
  development:
    -
      database: drupal
      exclude_table_data:
        - "*"
```

If you wish to omit entire tables--data AND structure--you will list those tables in `exclude_tables`.

```yaml
workflows:
  development:
    -
      database: drupal
      exclude_tables:
        - foo
        - bar
```
