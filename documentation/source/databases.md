# Databases

If a project uses at least one database, it must be defined in configuration for it to be included in the copy. You must give it an `id` at minimum. Once defined, it can be referenced later in the configuration. You may define multiple databases if necessary.

In cases where a database can be assumed, such as `export` without the use of `--database=NAME`, the first database ID listed in the environment list will be used. In the following configuration example, `primary` will be assumed the default database.

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
        mysqldump_options:
          - add-drop-database
          - bind-address
          - dump-date
```

Sometimes you might define the same database with multiple ids, if you want to have different levels of export. For example you might have one that excludes many tables, and another that excludes none, that latter serving as a backup solution when you want more content than you would during normal development.

The `mysqldump_options` allow you to customize the behavior of the CLI tool.

## Excluding Tables or Data

Often times when you are copying the content of a database, it is preferable to leave out the data from certain tables, such as in the case of cache tables. This is the reason for `exclude_table_data`. List one or more tables (astrix globbing allowed), whose _structure only_ should be copied.

```yaml
workflows:
  development:
    -
      database: drupal
      exclude_table_data:
        - cache*
        - batch
```

To export only table structure and no data, do like this:

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
