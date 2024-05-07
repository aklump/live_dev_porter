var lunrIndex = [{"id":"remote_install_alt","title":"Alternative Remote Installation","body":"To install Live Dev Porter on a remote server without using source control do the following.\n\n1. On the remote server create a folder _live_dev_porter_ as a sibling to your webroot.\n2. `cd` into that directory\n3. composer require aklump\/live-dev-porter:^0.0\n4. Open _.live\\_dev\\_porter\/config.yml_ and add ONLY the `live' environment and any workflows it uses from your local file.\n5. Edit _config.local.yml_ to include only include `local: live`\n6. Edit the remote `$PATH` to include _...live_dev_porter\/vendor\/bin_\n7. Configure the correct database connection, probably `mysql`... you do not need to separate the `password` out; include it in _config.yml_"},{"id":"changelog","title":"Changelog","body":"All notable changes to this project will be documented in this file.\n\nThe format is based on [Keep a Changelog](https:\/\/keepachangelog.com\/en\/1.0.0\/), and this project adheres to [Semantic Versioning](https:\/\/semver.org\/spec\/v2.0.0.html).\n\n## [0.0.147] - 2024-02-26\n\n### Added\n\n- `shell_commands.scp` configuration in _live_dev_porter.core.yml_\n- `scp -O` to support OS X Venture; https:\/\/aboutnetworks.net\/scp-macos13\/\n\n### Changed\n\n- `scp` command to `scp -O` in the mysql plugin.\n\n## [0.0.138] - 2023-09-26\n\n### Changed\n\n- All PHP Processors must use the namespace `AKlump\\LiveDevPorter\\Processors\\`\n\n## [0.0.120] - 2023-06-01\n\n### Added\n\n- You can now set the `local` or `remote` env from CLI using `ldp config local ` or `ldp config remote `, without opening an editor.\n\n## [0.0.109] - 2023-02-12\n\n### Changed\n\n- How the process command gets it's environment variables. Add --config and --verbose to the process command.\n\n### Removed\n\n- The --env option from the process command. To set the variables you must now use \"process --config\"\n\n## [0.0.105] - 2022-12-08\n\n### Added\n\n- `\\AKlump\\LiveDevPorter\\Processors\\PhpTrait` for processing PHP files secrets.\n\n## [0.0.101] - 2022-11-08\n\n### Added\n\n- `ldp push` operation\n- Added `preprocessors` to workflows for database push and pull.\n- configuration option `backup_remote_db_on_push`\n\n### Changed\n\n- `compress_pull_dumpfiles` has been renamed to `compress_dumpfiles`. If you have set this value you must update the variable name in your configuration. See _live_dev_porter.core.yml_ for default."},{"id":"local_build_files","title":"Creating Scaffold Files from the Local Environment","body":"> You want to copy un-versioned local files, e.g. _.htaccess, settings.local.php, .env_ to a source-controlled folder called _install\/_, at the same time removing any secrets. You do this so that these files can be source-controlled and used in installation processes. These are sometimes called scaffold files.\n\nThis is how you do that.\n\n1. Configure a second, local environment, e.g. `local`.\n3. Set `write_access` to `false`.\n2. Setup `files` as you would a normal remote, that is, with paths to the original files.\n4. Do not define `databases` because this will ensure only files are pulled, even without using `pull -f`.\n5. Now run `ldp pull local` to copy the files; notice how you specify the \"remote\" in the CLI argument.\n\n_.live_dev_porter\/config.yml_\n\n```yaml\nenvironments:\n  dev:\n    label: ITLS\n    write_access: true\n    plugin: default\n    base_path: \/alpha\/bravo\/app\n    command_workflows:\n      pull: develop\n    databases:\n      drupal:\n        plugin: lando\n        service: database\n    files:\n      install: install\n      public: web\/sites\/default\/files\n      private: private\/default\/files\n  local:\n    label: ITLS\n    write_access: false\n    plugin: default\n    base_path: \/alpha\/bravo\/app\n    files:\n      install: .\/\n```"},{"id":"databases","title":"Databases","body":"If a project uses at least one database, it must be defined in configuration. You must give it an ID. Using that ID, it can be referenced in other parts of the configuration. You may define multiple databases if that applies to your situation.\n\nYou must also define which plugin is used to access your database, along with the plugin-specifiy configuation. Example plugins are: _mysql_, _env_, _lando_, _lando_git_.\n\nIf you have more than one database defined, the first listed in the configuration will be assumed unless you specify otherwise with `--database=ID`. In the following configuration example, `primary` will be assumed the default database.\n\n```yaml\nenvironments:\n  -\n    id: local\n    databases:\n      primary:\n        plugin: lando\n        service: database\n      secondary:\n        plugin: lando\n        service: alt_database\n```\n\n## Excluding Tables or Data for Different Commands\n\nYou can omit entire tables using `exclude_tables`.\n\nYou may want to omit data from certain tables, such as in the case of cache tables. This is the reason for `exclude_table_data`. List one or more tables (astrix globbing allowed), whose _structure only_ should be copied.\n\nCreate one or more workflows with your table\/data exclusion rules. Then use those workflows as command arguments.\n\n```yaml\nworkflows:\n  development:\n    -\n      database: drupal\n      exclude_table_data:\n        - cache*\n        - batch\n```\n\nTo export only table structure and no data from any table, do like this:\n\n```yaml\nworkflows:\n  development:\n    -\n      database: drupal\n      exclude_table_data:\n        - \"*\"\n```\n\nIf you wish to omit entire tables--data AND structure--you will list those tables in `exclude_tables`.\n\n```yaml\nworkflows:\n  development:\n    -\n      database: drupal\n      exclude_tables:\n        - foo\n        - bar\n```\n\n## Explicitly Including Tables\n\nThe counterpoint keys are also available: `include_table_structure`, and `include_tables_and_data`. They cannot, however be used at the same time as their `exclude_` counterparts.\n\nTo cherry pick only tables and data use `include_tables_and_data`.\nTo cherry pick table structure only use `include_table_structure`."},{"id":"processor_development","title":"Developing New Processors","body":"You will probably want to test your processors in isolation when developing them, as this will be quicker in most all cases.\n\nOpen the processor config environment editor:\n\n```shell\nldp process --config\n```\n\nSet the desired values to be sent to the processor:\n\n```dotenv\nCOMMAND=pull\nLOCAL_ENV_ID=dev\n#REMOTE_ENV_ID=\nDATABASE_ID=drupal\n#DATABASE_NAME=\n#FILES_GROUP_ID=\n#FILEPATH=\n#SHORTPATH=\nIS_WRITEABLE_ENVIRONMENT=true\n```\n\nNow run the processor. Using `-v` will allow you to see the variables that are being sent.\n\n```shell\nldp process -v delete_users.sh\n```"},{"id":"logging","title":"Enable Logging","body":"Export the variable `LOGFILE` with an absolute path to enable logging.\n\n```shell\n$ export LOGFILE=\/some\/path\/to\/app.log\n$ ldp export\n```\n\nDisable logging by setting that same variable to an empty string:\n\n```shell\n$ export LOGFILE=''\n```"},{"id":"environment_roles","title":"Environment Roles","body":"All public-facing websites have a server that acts as the production or live server. It can be said it plays the _production_ role.\n\nMost sites have a counterpart install, where development takes place; typically on the developer's laptop. This \"server\" is said to play the _development_ role.\n\nThere may be a third installation where new features are reviewed before they are pushed to the live server. This can be the _test_ or _staging_ server, playing the selfsame role.\n\nBy these three examples, we have described what is meant by environment roles. When using _Live Dev Porter_, you must define at minimum one role and you may define an unlimited number of roles. The typical, as described above, would be two or three.\n\nThe flow of data between the environments is the next topic of discussion. Data, that is files not stored in source control and database content, should **never** flow into the live server. This is because the live server should always be seen as the single source of truth. Therefore it stands to reason that the production role should never be given `write_access` in our configuration.\n\nWhereas data should be able to flow from the live server into either development or test. Therefore these environments are marked as having `write_access`."},{"id":"environments","title":"Environments","body":"The configuration of `environments` is where you define real-life server instances in the configuration files.\n\nEvery environment must tell it's role.\n\nThis item is where _file_groups_ are mapped to actual directories in the environment.\n\nDatabase connections are defined in the environment."},{"id":"file_groups","title":"File Groups","body":"File groups are for handling files and directories which are not in source control. For example Drupal-based websites have the concept of a public directory for user uploads. It is for such case that this concept is designed.\n\nDefine as many file groups as you want, or none if appropriate. At minimum you must assign an `id` because this is what will be referenced to map the file group to actual file paths later in an `environment` definition.\n\nThere are two optional filters which can be used, `include` and `exclude`. Only one may be used, per file group. For syntax details see the [rsync pattern rules](https:\/\/www.man7.org\/linux\/man-pages\/man1\/rsync.1.html#INCLUDE\/EXCLUDE_PATTERN_RULES). Here is an incomplete summary, covering the main points:\n\n1. If the pattern starts with a `\/` then the match is only valid in the top-level directory, otherwise the match is checked recursively in descendent directories.\n2. If the pattern ends with a \/ then it will only match a directory.\n3. Using `*` matches any characters stopping at a slash, whereas...\n4. Using `**` matches any characters, including the slash.\n\nIf the `include` filter is used, for a file or folder to be copied it must be matched by an `include` rule. On the other hand, if the `exclude` filter is used then a file will **not** be copied if it matches an `exclude` rule.\n\n> If a local folder or file exists, yet it appears in a file group's `exclude` rules, it will never be removed by the pull command. You would have to manually remove it.\n\n> If a remote folder or file that was previously pulled gets deleted, it will be automatically be deleted from your local environment the next time you pull.\n\n## Beware of Directory Contents\n\nIf you are trying to match a directory, then you are also trying to match it's contents. Make sure to end the line with a '\/' or the contents will not be considered. In _Example 1_, `\/members\/100` will be treated as a file and if it happens to be a directory, the content will never be seen.\n\nHowever as shown in _Example 2 (A & B)_ using two syntax variations, `\/members\/100` will be treated as a directory, and it's contents will be excluded\/included as appropriate to the directive.  **The ending `\/` or `\/**` is critical.**\n\nExample 1:\n\n```yaml\nfile_groups:\n  test_content:\n    include:\n      - \/members\/100\n```\n\nExample 2A:\n\n```yaml\nfile_groups:\n  test_content:\n    include:\n      - \/members\/100\/\n```\n\nExample 2B:\n\n```yaml\nfile_groups:\n  test_content:\n    include:\n      - \/members\/100\/**\n```"},{"id":"import","title":"Import","body":"When you call `ldp import`, a database backup is taken which contains all tables and data. It has a filename that begins with _rollback_. Only N most recent rollback files are kept. N is configurable as `max_database_rollbacks_to_keep`.\n\nTo revert use the `import` command and select the rollback with the appropriate timestamp, presumably the most newest."},{"id":"lando","title":"Lando","body":"This article describes one way to use Live Dev Porter with Lando, which leverages the container so no host dependencies are required. You will need to use `lando ldp ...` when executing commands. In this example we're setting up a local environment called `dev` in the configuration.\n\n## Base Path Must Be A Container Path\n\nYou must define _base_path_ using a container path, NOT a path on the host machine.\n\n_.live_dev_porter\/config.yml_ or _.live_dev_porter\/config.local.yml_\n\n```yaml\nenvironments:\n  dev:\n    base_path: \/app\n    ...\n```\n\n## Correct Database Plugin\n\nYou must use the correct database plugin. Surprisingly, do not use one of the `lando*` database plugins, (which are only for running LDP _outside_ of the container). Instead use either the `env` or `mysql` database plugin:\n\n_.live_dev_porter\/config.yml_ or _.live_dev_porter\/config.local.yml_\n\n```yaml\nenvironments:\n  dev:\n    ...\n    databases:\n      drupal:\n        plugin: env\n        path: .env\n        var: DATABASE_URL\n```\n\n## Add Tooling\n\nAdd the following so that `lando ldp` can be used.\n\n_.lando.yml_\n\n```yaml\ntooling:\n  ldp:\n    service: appserver\n    description: Run Live Dev Porter from the container.\n    cmd: \"\/app\/vendor\/bin\/ldp\"\n    user: root\n```"},{"id":"readme","title":"Live Dev Porter","body":"![live_dev_porter](..\/..\/images\/live-dev-porter.jpg)\n\n## Summary\n\nSimplifies the management and transfer of assets between website environments.\n\n**Visit  for full documentation.**\n\n## Quick Start\n\n1. Require in your project using `composer require aklump\/live-dev-porter:^0.0`\n2. Ensure execute permissions: `chmod u+x .\/vendor\/bin\/ldp`\n3. Initialize your project using `.\/vendor\/bin\/ldp init`\n4. (To migrate from Loft Deploy jump below...)\n5. Open _.live\\_dev\\_porter\/config.yml_ and modify as needed.\n6. **Ensure _.live\\_dev\\_porter\/config.local.yml_ is ignored by your SCM!**\n7. Open _.live\\_dev\\_porter\/config.local.yml_ and define the correct `local` and `remote` environment IDs as defined in _config.yml_.\n8. Run `.\/vendor\/bin\/ldp configtest` and work through any failed tests.\n\n### Migrating from Loft Deploy?\n\n1. `rm .live_dev_porter\/config*`\n2. `.\/vendor\/bin\/ldp config-migrate .loft_deploy`\n3. Rewrite any hooks as processors.\n4. Return to where you left off above.\n\n### Optional Shorthand `ldp` instead of `.\/vendor\/bin\/ldp`\n\n#### Option A: `$PATH`\n\n_This option has the advantage that any other composer binary in your project will be executable as well._\n\n1. Add _\/path\/to\/project\/root\/vendor\/bin_ to your `$PATH`.\n\n_~\/.bash_profile_\n\n```shell\nPATH=\"\/path\/to\/project\/root\/vendor\/bin\/ldp:$PATH\"\n```\n\n#### Option B: alias\n\n_This option is singularly focused in terms of what it affects._\n\n_~\/.bash_profile_\n\n1. Add an alias called ldp that points to _\/path\/to\/project\/root\/vendor\/bin\/ldp_.\n\n```shell\nalias ldp=\"\/path\/to\/project\/root\/vendor\/bin\/ldp\"\n```\n\n#### Both Options Continued\n\n2. Type `ldp` to test if it worked... you should see available commands\n3. Now use `ldp` from anywhere within your project, instead of `.\/vendor\/bin\/ldp` from the root.\n4. Don't worry if you have more than one project using _Live Dev Porter_ because this alias will work for multiple projects as long as they use the same version, and usually even if the versions differ.\n\n## Quick Start Remote\n\n1. Deploy your code to your remote server.\n2. On the remote server type `.\/vendor\/bin\/ldp config -l`\n\n## Installation\n\nThe installation script above will generate the following structure where `.` is your repository root.\n\n    .\n    \u2514\u2500\u2500 .live_dev_porter\n    \u2502   \u251c\u2500\u2500 config.local.yml\n    \u2502   \u2514\u2500\u2500 config.yml\n    \u2514\u2500\u2500 {public web root}\n\n## Configuration Files\n\nRefer to the file(s) for documentation about configuration options.\n\n| Filename | Description | VCS |\n|----------|----------|---|\n| _.live\\_dev\\_porter\/config.yml_ | Configuration shared across all server environments: prod, staging, dev  | yes |\n| _.live\\_dev\\_porter\/config.local.yml_ | Configuration overrides for a single environment; not version controlled. | no |\n\n## Usage\n\n* To see all commands use `.\/vendor\/bin\/ldp`\n\n## Contributing\n\nIf you find this project useful... please consider [making a donation](https:\/\/www.paypal.com\/cgi-bin\/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Gratitude%20for%20aklump%2Flive_dev_porter)."},{"id":"loft_deploy_migrations","title":"Migrating From Loft Deploy","body":"1. `.\/vendor\/aklump\/live-dev-porter\n   \/live_dev_porter.sh config-migrate`\n2. Review the contents of _.live_dev_porter_...\n3. Fill in `@todo` appearing in the new config.\n4. Rewrite any hooks as processors.\n5. When convinced all is well, delete _.loft_deploy_"},{"id":"troubleshooting","title":"On Dreamhost, Export Failed Due to PHP Version","body":"1. On the remote server.\n2. Open _~\/.bashrd_\n3. Add this line, adjusting as appropriate: `PATH=\"\/usr\/local\/php74\/bin:$PATH\"`\n\nThe problem was that PHP 7.4 was being added in _~\/.bash_profile_ which is only for login shells. The export connects with a non-login shell and so the default php was getting loaded. By placing it in _~\/.bashrc_ it gets loaded.\n\n# A Processor Hangs\n\n*Check to see if you are using a command that is prompting for user input, e.g. `drush pm-enable ...` will hang unless you have the `-y` flag. So the correct command within a processor is `drush pm-enable -y ...`\n\n* You can see the output of processor if you use the developer command `processor`; that is a good way to see if there are any user prompts."},{"id":"plugins","title":"Plugins","body":"> This page needs updating.\n\n1. Plugins are folders saved to the _plugins\/_ directory, resembling the following structure.\n\n    ```\n    \u2514\u2500\u2500 mysql\n        \u251c\u2500\u2500 README.md\n        \u251c\u2500\u2500 config.yml\n        \u2514\u2500\u2500 plugin.sh\n    ```\n2. _config.yml_ should all configuration that the plugin is expecting to use.\n3. _plugin.sh_ should contain functions; all that are public must be prefixed by the plugin name:\n\n   ```bash\n   function mysql_on_init() {\n     ensure_files_local_directories && succeed_because \"Updated fetch structure at $(path_unresolve \"$APP_ROOT\" \"$FETCH_FILES_PATH\")\"\n   }\n   ```\n4. Plugins may provide the following functions:\n    1. Plugins implement hooks which are functions named by: PLUGIN_on_*.\n    2. To find the hooks available, search the code for `plugin_implements` and `call_plugin`.\n    3. Plugins may define private functions, but they should begin with an underscore.\n\n       ```bash\n       function _mysql_get_remote_env() {\n         case $REMOTE_ENV_ID in\n         production)\n           echo 'live' && return 0\n           ;;\n         staging)\n           echo 'test' && return 0\n           ;;\n         esac\n         exit_with_failure \"Cannot determine Pantheon environment using $REMOTE_ENV_ID\"\n       }\n        ```\n\n## Error Conditions\n\n1. Plugins should use `fail_because` && `succeed_because`\n2. Plugins should return non-zeros\n3. Plugins should not use `exit_with_*` methods; those are for the controller.\n\n## Tests\n\nAdd tests to your plugin:\n\n1. Create PLUGIN.tests.sh, e.g. \"default.tests.sh\"\n2. Follow the Cloudy testing framework.\n3. Run tests with `.\/live_dev_porter tests`"},{"id":"processors","title":"Processors","body":"> The working directory for processors is always the app root.\n\n> `$ENVIRONMENT_ID` will always refer to the source, which in the case of pull is remote, in the case of export local, etc.\n\n* To provide feedback to the user the processor should use echo\n* The file must exit with non-zero if it fails.\n* If you wish to indicated the processor was skipped or not applied exit with 255; see examples below.\n* When existing with code 1-254 a default failure message will always be displayed. If the processor echos a message, this default will appear after the response.\n* If the file exits with a zero, there is no default message.\n\n## Database Processing\n\n* Notice the use of `query` below; this operates on the database being processed and has all authentication embedded in it. Use this to affect the database.\n* The result of the queries is stored in a file, whose path is written to `$query_result`; see example using `$(cat $query_result)`.\n* Database preprocessing is available for `push` and `pull` operations only at this time.\n\n_An example bash processor for a database command:_\n\n```shell\n#!\/usr\/bin\/env bash\n\n# Only do processing when we have a database event.\n[[ \"$DATABASE_ID\" ]] || exit 255\n\n# Reduce our users to at most 20.\nif ! query 'DELETE FROM users WHERE uid > 20'; then\n  echo \"Failed to reduce the user records in $DATABASE_NAME.\"\n  exit 1\nfi\n\nquery 'SELECT count(*) FROM users' || exit 1\necho \"$(cat $query_result) total users remain in $DATABASE_NAME\"\n```\n\n## File Processing\n\nFor file groups having `include` filter(s), you may create _processors_, or small files, which can mutate the files comprised by that list.\n\nA use case for this is removing the password from a database credential when the file containing it is pulled locally. This is important if you will be committing a scaffold version of this configuration file containing secrets. The processor might replace the real password with a token such as `PASSWORD`. This will make the file save for inclusion in source control.\n\n_An example bash processor for a file:_\n\n```shell\n#!\/usr\/bin\/env bash\n\n# Only do processing when we have a file event.\n[[ \"$COMMAND\" != \"pull\" ]] && exit 255\n[[ \"$FILES_GROUP_ID\" ]] || exit 255\n\ncontents=$(cat \"$FILEPATH\")\n\nif ! [[ \"$contents\" ]]; then\n  echo \"$SHORTPATH was an empty file.\"\n  exit 1\nfi\necho \"Contents approved in $SHORTPATH\"\n```\n\nWhen creating PHP processors, you should **make all methods private, except those that are to be considered callable as a processor**. The processor indexing method will expose all public methods in the options menu.\n\n**Use the namespace `AKlump\\LiveDevPorter\\Processors\\`.**\n\n_Here is an example in PHP:_\n\n```php"},{"id":"pull","title":"Pulling Remote to Local","body":"## `ldp pull`\n\nThis is like `git pull`, it will copy the remote database and files, depending on your configuration, to your local environment.\n\n## Is There Something Like `git reset` for the Database?\n\nBy default the dumpfile, which is downloaded, is deleted upon successful import into the local database. This behavior can be changed by adding the following to your configuration:\n\n```yaml\ndelete_pull_dumpfiles: false\n```\n\nYou might want to do this to give you a way to reset to the remote database without having to go back to the server. When `false`, the dumpfile remains in _.live_dev_porter\/data\/*_ after you pull it down. It will show up as _pull.sql_ in the list when you call `ldp import`.\n\n**However, if you are using a workflow to sanitize your database, then keeping these \"unsanitized\" database dumps is a security concern. It is better to leave `delete_pull_dumpfiles: true` and export your sanitized local database in your pull workflow. This will still give you the \"reset\" ability, but without the security concern.**\n\n## Cherry Picking Some Tables\n\nLet's say you're working on a feature that affects the data in only two tables. Rather than waiting for the entire live database to export and download, with a local backup, you can do something like the following. It will only pull the tables you list and is therefore much faster. For further speeding up of things, you can choose to omit the local backup using `--skip-local-backup`.\n\n1. Create a workflow with inclusive tables using `include_table_structure_and_data`, e.g.\n\n```yaml\nworkflows:\n  cherry_pick_wf:\n    processors:\n      - dev_module_handler.sh\n    databases:\n      drupal:\n        drop_tables: false\n        include_tables_and_data:\n          - registry\n          - registry_file\n```\n\n1. Be sure to add `drop_tables: false` to the workflow as shown. This will prevent your local database from loosing the tables and data that are not listed in `include_tables_and_data`. By default, all tables in your local database are dropped during a `pull` command. That is not what you want in this scenario!\n3. Ensure that the configuration for this workflow exists in both environments (local and remote) and that it is also identical on both. Remember when you pull with a workflow, the configuration in both environments must match.\n4. Now `pull` and specify this particular workflow as shown:\n\n```php\nldp pull --wf=cherry_pick_wf --no-local-backup\n```"},{"id":"push","title":"Push","body":"## Database Push\n\n* If `backup_remote_db_on_push` is configured to `true` then the remote database will be exported using `ldp export` and the workflow that is configured for `push` in the local environment. It will be saved to the data directory in the remote environment, e.g., _.live_dev_porter\/data\/live\/database\/drupal\/live_drupal_20221109T033709.sql.gz_."},{"id":"remote","title":"Remote Environment","body":"> You should use key-based authentication to avoid password prompts.\n\n## _config.local.yml_\nIn _config.local.php_ on a developer's machine, that is to say the _local perspective_ the remote environment will usually be either production\/live or staging\/test, e.g.,\n\n```yaml\nlocal: dev\nremote: live\n```\n\nHowever, this is how _config.local.php_ should look on the production server--the _remote perspective_.\n\n```yaml\nlocal: live\nremote:\n```\n\n## Default Configuration\n\n```yaml\nenvironments:\n  dev:\n    write_access: true\n  live:\n    write_access: false\n    base_path: \/var\/www\/site.com\/app\n    ssh: foobar@123.mygreathost.com\n```\n\n## Troubleshooting\n\n`ldp remote` will connect you to the remote environment and `cd` to the base path. It you do not land in the base path, check _~\/.bashrc_ and _~\/.bash_profile_ for the presence of a `cd` command in there. You will need to comment that out or remove that line if you wish for LDP to land you in the basepath.\n\n## _.profile_ not loading on login\n\nThe app tries to connect as a login shell, but in some cases this may not be possible.  If not then you may find that files such as _.profile_ are not loaded and you're missing some configuration.\n\nSee the function `default_on_remote_shell` for more details.\n\n## Wrong PHP version\n\n- Make sure .bashrc on the remote sets the correct version."},{"id":"remote_environment","title":"Remote Environment","body":"## `configtest` fails on Live has \"*\" installed\n\nTo fix this you need to ..."},{"id":"sanitation","title":"Sanitation of Vulnerable Data","body":"This example shows how to setup a processor that will remove the password and secrets from a non-versioned _.env_ file on `pull`.\n\n1. Define a file group `install`, which includes a file called _.env_.\n2. Next, map the file group to your local, e.g., `environments.0.files.install`\n3. _(You will need to also map it to the remote, but that's covered elsewhere.)_\n4. Define a workflow: `development`\n5. Add to that workflow a processor item pointing to a class::method, in this case `RemoveSecrets::process`\n6. Configured the environment to use the `development` workflow by default on `pull`\n7. Create the processor class::method as _.\/live_dev_porter\/processors\/RemoveSecrets.php_. Notice the trait and the parent class and study those for more info.\n\n## Configuration\n\n> This is not a complete configuration, for example the remove environment is missing; just the items needed to illustrate this concept are shown.\n\n_.live_dev_porter\/config.yml_\n\n```yaml\nfile_groups:\n  install:\n    include:\n      - \/.env\n\nworkflows:\n  development:\n    -\n      processor: RemoveSecrets::process\n\nenvironments:\n  local:\n    files:\n      install: install\/default\/scaffold\n    command_workflows:\n      pull: development\n```\n\n## The Processor File\n\n_.\/live_dev_porter\/processors\/RemoveSecrets.php_\n\n```php"},{"id":"search__results","title":"Search  Results","body":"# Search Results"},{"id":"source_control","title":"Source Control","body":"You should add the directory _.live_dev_porter_ to your project's repository, with the exception of the following files; they must be excluded.\n\n```\n.live_dev_porter\n\u251c\u2500\u2500 .cache\n\u2514\u2500\u2500 config.local.yml\n```"},{"id":"connection_problems","title":"Trouble Connecting to Remote","body":"## `Too many authentication failures`\n\n1. `mv ~\/.ssh\/config ~\/.ssh\/c`\n2.\n\n## Restart the Mac\n\nYes, actually this fixed it for me when nothing else here would.\n\n## Reinstall the SSH key\n\n1. Make sure the value for `Host` in _~\/.ssh\/config_ on your local matches the remote IP or domain.\n2. Make sure the `IdentityFile` exists.\n3. Paste the contents of `.pub` of the IndentiyFile to the remote _authorized_keys_\n4. Update permissions on remote and local i.e., `chmod 0700 ~\/.ssh;chmod 0600 ~\/.ssh\/*;chmod 0644 ~\/.ssh\/*.pub`\n\n## Mitigation Options\n\n### Force login using password\n\n1. Add this to the ssh: `-o PreferredAuthentications=password`\n2. Enter the password to see if you can connect that way. If so the issue is with the certificate."},{"id":"installation","title":"Troubleshooting Installation","body":"## Failed due to missing configuration; please add \"local\"\n\nUpdate to the newest version of Live Dev Porter."},{"id":"php","title":"Using PHP in the Codebase","body":"To execute OOP PHP, you must use:\n\n`call_php_class_method \"\\AKlump\\LiveDevPorter\\Helpers\\FooBarBaz::__invoke(aaron_develop,drupal,drupal,1584,1)\"`\n\nUse this pattern when the method returns a value, so that the app will handle errors correctly.\n\n```shell\nlocal result\nresult=$(call_php_class_method \"\\AKlump\\LiveDevPorter\\Helpers\\FooBarBaz::__invoke(aaron_develop,drupal,drupal,1584,1)\")\n[[ $? -ne 0 ]] && fail_because \"$result\" && return 1\necho \"$result\"\n```\n\nOther, legacy options, not well-documented, try not to use.\n`echo_php_class_method`\n`call_php_class_method_echo_or_fail \"\\AKlump\\LiveDevPorter\\Config\\AlphaBravo::build(CACHE_DIR=$CONFIG_DIR\/.cache&FOO=123)\"`\n\nNotice the arguments must be serialized as CSV or a query string. However the values needn't be wrapped in single\/double quotes.\n\n## Code Resources\n\n* _class_method_caller.php_\n* `\\AKlump\\LiveDevPorter\\Php\\ClassMethodCaller`"},{"id":"workflows","title":"Workflows","body":"> Suggestion: Name your workflows using a _verb in the imperative_, e.g. \"archive\", \"develop\".\n\n## GOTCHA\n\n> When you pull, the workflow configuration is read from the local environment!\n\nThe means you MUST always keep _.live_dev_porter\/config.yml_ in sync between environments otherwise strange things being to happen."}]