# Databases

If a project uses at least one database, it must be defined in configuration for it to be included in the copy. You must give it an `id` at minimum. Once defined, it can be referenced later in the configuration. You may define multiple databases if necessary.

Sometimes you might define the same database with multiple ids, if you want to have different levels of export. For example you might have one that excludes many tables, and another that excludes none, that latter serving as a backup solution when you want more content than you would during normal development.

Often times when you are copying the content of a database, it is preferable to leave out the data from certains tables, such as in the case of cache tables. This is the reason for `exclude_table_data`. List one or more tables (astrix globbing allowed), whose _structure only_ should be copied.

If you wish to omit entire tables--data plus structure--you will list those tables in `exclude_tables`.

The `mysqldump_options` allow you to customize the behavior of the CLI tool.
