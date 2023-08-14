<!--
id: pull
tags: ''
-->

# Pulling Remote to Local

## `ldp pull`

This is like `git pull`, it will copy the remote database and files, depending on your configuration, to your local environment.

## Is There Something Like `git reset` for the Database?

By default the dumpfile, which is downloaded, is deleted upon successful import into the local database.  This behavior can be changed by adding the following to your configuration:

```yaml
delete_pull_dumpfiles: false
```

You might want to do this to give you a way to reset to the remote database without having to go back to the server.  When `false`,  the dumpfile remains in _.live_dev_porter/data/*_ after you pull it down. It will show up as _pull.sql_ in the list when you call `ldp import`.

**However, if you are using a workflow to sanitize your database, then keeping these "unsanitized" database dumps is a security concern.  It is better to leave `delete_pull_dumpfiles: true` and export your sanitized local database in your pull workflow.  This will still give you the "reset" ability, but without the security concern.**
