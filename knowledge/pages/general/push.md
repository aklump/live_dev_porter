<!--
id: push
tags: ''
-->

# Push

## Database Push

* If `backup_remote_db_on_push` is configured to `true` then the remote database will be exported using `ldp export` and the workflow that is configured for `push` in the local environment. It will be saved to the data directory in the remote environment, e.g., _.live_dev_porter/data/live/database/drupal/live_drupal_20221109T033709.sql.gz_.
