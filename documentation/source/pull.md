# Pulling Remote to Local

## `ldp pull`

This is like git pull, it will copy the remote database and files, depending on your configuration, to your local environment.

## Is There Something Like `git reset` for the Database?

The database dumpfile remains in your local cache after you pull it down. You may reset your local database to that file if you do not need to export and download a fresh copy. To do so, use `ldp import` and look for and choose the file named _pull.sql_. This will save you time if it is current enough.
