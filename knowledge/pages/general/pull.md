<!--
id: pull
tags: ''
-->

# Pulling Remote to Local

## `ldp pull`

This is like `git pull`, it will copy the remote database and files, depending on your configuration, to your local environment.

## Is There Something Like `git reset` for the Database?

By default the dumpfile, which is downloaded, is deleted upon successful import into the local database. This behavior can be changed by adding the following to your configuration:

```yaml
delete_pull_dumpfiles: false
```

You might want to do this to give you a way to reset to the remote database without having to go back to the server. When `false`, the dumpfile remains in _.live_dev_porter/data/*_ after you pull it down. It will show up as _pull.sql_ in the list when you call `ldp import`.

**However, if you are using a workflow to sanitize your database, then keeping these "unsanitized" database dumps is a security concern. It is better to leave `delete_pull_dumpfiles: true` and export your sanitized local database in your pull workflow. This will still give you the "reset" ability, but without the security concern.**

## Cherry Picking Some Tables

Let's say you're working on a feature that affects the data in only two tables. Rather than waiting for the entire live database to export and download, with a local backup, you can do something like the following. It will only pull the tables you list and is therefore much faster. For further speeding up of things, you can choose to omit the local backup using `--skip-local-backup`.

1. Create a workflow with inclusive tables using `include_table_structure_and_data`, e.g.

```yaml
workflows:
  cherry_pick_wf:
    processors:
      - dev_module_handler.sh
    databases:
      drupal:
        drop_tables: false
        include_tables_and_data:
          - registry
          - registry_file
```

1. Be sure to add `drop_tables: false` to the workflow as shown. This will prevent your local database from loosing the tables and data that are not listed in `include_tables_and_data`. By default, all tables in your local database are dropped during a `pull` command. That is not what you want in this scenario!
3. Ensure that the configuration for this workflow exists in both environments (local and remote) and that it is also identical on both. Remember when you pull with a workflow, the configuration in both environments must match.
4. Now `pull` and specify this particular workflow as shown:

```php
ldp pull --wf=cherry_pick_wf --no-local-backup
```
