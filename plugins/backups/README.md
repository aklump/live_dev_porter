# Backups Plugin

Allows "pull" to utilize local backup files downloaded from the remote.

1. For your `remote` set the plugin as `backups` as shown.
2. Download your database backup to the location of `path`.  **Globs may be used e.g., `live_db_*.sql`, where the basename might contain a date like `live_db_20250221.sql`.**
3. Run `ldp pull`

```shell
environments:
  backups:
    base_path: /path/to/app/
    label: Production files downloaded from server.
    plugin: backups
    write_access: false
    databases:
      default:
        # The database backup from live was downloaded to your computer.
        path: /Users/aklump/Downloads/live_db.sql
```
