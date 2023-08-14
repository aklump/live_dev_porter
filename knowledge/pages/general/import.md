<!--
id: import
tags: ''
-->

# Import

When you call `ldp import`, a database backup is taken which contains all tables and data. It has a filename that begins with _rollback_. Only N most recent rollback files are kept. N is configurable as `max_database_rollbacks_to_keep`.

To revert use the `import` command and select the rollback with the appropriate timestamp, presumably the most newest.
