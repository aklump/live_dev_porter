var tipuesearch = {"pages":[{"title":"Changelog","text":"  All notable changes to this project will be documented in this file.  The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.  [Unreleased]   lorem   [N.N.N] - YYYY-MM-DD  Added   lorem   Changed   lorem   Deprecated   lorem   Removed   lorem   Fixed   lorem   Security   lorem  ","tags":"","url":"CHANGELOG.html"},{"title":"Live Dev Porter","text":"    Summary  Simplifies the management and transfer of assets between website environments.  Visit https:\/\/aklump.github.io\/live_dev_porter for full documentation.  Quick Start   Require in your project using composer require aklump\/live-dev-porter Ensure execute permissions: chmod u+x .\/vendor\/bin\/ldp Initialize your project using .\/vendor\/bin\/ldp init (To migrate from Loft Deploy jump below...) Open .live_dev_porter\/config.yml and modify as needed. Ensure config.local.yml is ignored by your SCM! Open .live_dev_porter\/config.local.yml and define the correct local and remote environment IDs as defined in config.yml. Run .\/vendor\/bin\/ldp configtest and work through any failed tests.   Migrating from Loft Deploy?   rm .live_dev_porter\/config* .\/vendor\/bin\/ldp config-migrate .loft_deploy Rewrite any hooks as processors. Return to where you left off above.   Optional Shorthand ldp instead of .\/vendor\/bin\/ldp   Add .\/vendor\/bin to your $PATH variable (probably in ~\/.bash_profile). Type ldp to test if it worked... you should see available commands Now use ldp from anywhere within your project, instead of .\/vendor\/bin\/ldp from the root. Don't worry if you have more than one project using Live Dev Porter because this alias will work for multiple projects as long as they use the same version, and usually even if the versions differ.   Quick Start Remote   Deploy your code to your remote server. On the remote server type .\/vendor\/bin\/ldp config -l   Installation  The installation script above will generate the following structure where . is your repository root.  . \u2514\u2500\u2500 .live_dev_porter \u2502   \u251c\u2500\u2500 config.local.yml \u2502   \u2514\u2500\u2500 config.yml \u2514\u2500\u2500 {public web root}   Configuration Files  Refer to the file(s) for documentation about configuration options.       Filename   Description   VCS       .live_dev_porter\/config.yml   Configuration shared across all server environments: prod, staging, dev   yes     .live_dev_porter\/config.local.yml   Configuration overrides for a single environment; not version controlled.   no     Usage   To see all commands use .\/vendor\/bin\/ldp   Contributing  If you find this project useful... please consider making a donation. ","tags":"","url":"README.html"},{"title":"Databases","text":"  If a project uses at least one database, it must be defined in configuration for it to be included in the copy. You must give it an id at minimum. Once defined, it can be referenced later in the configuration. You may define multiple databases if necessary.  In cases where a database can be assumed, such as export without the use of --database=NAME, the first database ID listed in the environment list will be used. In the following configuration example, primary will be assumed the default database.  environments:   -     id: local     databases:       primary:         plugin: lando         service: database       secondary:         plugin: lando         service: alt_database         mysqldump_options:           - add-drop-database           - bind-address           - dump-date   Sometimes you might define the same database with multiple ids, if you want to have different levels of export. For example you might have one that excludes many tables, and another that excludes none, that latter serving as a backup solution when you want more content than you would during normal development.  The mysqldump_options allow you to customize the behavior of the CLI tool.  Excluding Tables or Data  Often times when you are copying the content of a database, it is preferable to leave out the data from certain tables, such as in the case of cache tables. This is the reason for exclude_table_data. List one or more tables (astrix globbing allowed), whose structure only should be copied.  workflows:   development:     -       database: drupal       exclude_table_data:         - cache*         - batch   To export only table structure and no data, do like this:  workflows:   development:     -       database: drupal       exclude_table_data:         - \"*\"   If you wish to omit entire tables--data AND structure--you will list those tables in exclude_tables.  workflows:   development:     -       database: drupal       exclude_tables:         - foo         - bar  ","tags":"","url":"databases.html"},{"title":"Environment Roles","text":"  All public-facing websites have a server that acts as the production or live server. It can be said it plays the production role.  Most sites have a counterpart install, where development takes place; typically on the developer's laptop. This \"server\" is said to play the development role.  There may be a third installation where new features are reviewed before they are pushed to the live server. This can be the test or staging server, playing the selfsame role.  By these three examples, we have described what is meant by environment roles. When using Live Dev Porter, you must define at minimum one role and you may define an unlimited number of roles. The typical, as described above, would be two or three.  The flow of data between the environments is the next topic of discussion. Data, that is files not stored in source control and database content, should never flow into the live server. This is because the live server should always be seen as the single source of truth. Therefore it stands to reason that the production role should never be given write_access in our configuration.  Whereas data should be able to flow from the live server into either development or test. Therefore these environments are marked as having write_access. ","tags":"","url":"environment_roles.html"},{"title":"Environments","text":"  The configuration of environments is where you define real-life server instances in the configuration files.  Every environment must tell it's role.  This item is where file_groups are mapped to actual directories in the environment.  Database connections are defined in the environment. ","tags":"","url":"environments.html"},{"title":"File Groups","text":"  File groups are for handling files and directories which are not in source control. For example Drupal-based websites have the concept of a public directory for user uploads. It is for such case that this concept is designed.  Define as many file groups as you want, or none if appropriate. At minimum you must assign an id because this is what will be referenced to map the file group to actual file paths later in an environment definition.  There are two optional filters which can be used, include and exclude. Only one may be used, per file group. For syntax details see the rsync pattern rules. Here is an incomplete summary, covering the main points:   If the pattern starts with a \/ then the match is only valid in the top-level directory, otherwise the match is checked recursively in descendent directories. If the pattern ends with a \/ then it will only match a directory. Using * matches any characters stopping at a slash, whereas... Using ** matches any characters, including the slash.   If the include filter is used, for a file or folder to be copied it must be matched by an include rule. On the other hand, if the exclude filter is used then a file will not be copied if it matches an exclude rule.     If a local folder or file exists, yet it appears in a file group's exclude rules, it will never be removed by the pull command. You would have to manually remove it.      If a remote folder or file that was previously pulled gets deleted, it will be automatically be deleted from your local environment the next time you pull.  ","tags":"","url":"file_groups.html"},{"title":"Import","text":"  When you import a database backup is taken which contains all tables and data. It has a filename that begins with rollback. Only N most recent rollback files are kept. N is configurable as max_database_rollbacks_to_keep.  To revert use the import command and select the rollback with the appropriate timestamp, presumably the most newest. ","tags":"","url":"import.html"},{"title":"Creating Scaffold Files from the Local Environment","text":"     You want to copy un-versioned local files, e.g. .htaccess, settings.local.php, .env to a source-controlled folder called install\/, at the same time removing any secrets. You do this so that these files can be source-controlled and used in installation processes. These are sometimes called scaffold files.   This is how you do that.   Configure a second, local environment, e.g. local. Set write_access to false. Setup files as you would a normal remote, that is, with paths to the original files. Do not define databases because this will ensure only files are pulled, even without using pull -f. Now run ldp pull local to copy the files; notice how you specify the \"remote\" in the CLI argument.   .live_dev_porter\/config.yml  environments:   dev:     label: ITLS     write_access: true     plugin: default     base_path: .\/     command_workflows:       pull: develop     databases:       drupal:         plugin: lando         service: database     files:       install: install       public: web\/sites\/default\/files       private: private\/default\/files   local:     label: ITLS     write_access: false     plugin: default     base_path: .\/     files:       install: .\/  ","tags":"","url":"local_build_files.html"},{"title":"Migrating From Loft Deploy","text":"   .\/vendor\/aklump\/live-dev-porter \/live_dev_porter.sh config-migrate Review the contents of .live_dev_porter... Fill in @todo appearing in the new config. Rewrite any hooks as processors. When convinced all is well, delete .loft_deploy  ","tags":"","url":"loft-deploy-migrations.html"},{"title":"Plugins","text":"     This page is not current and needs updating.    Plugins are folders saved to the plugins\/ directory, resembling the following structure. \u2514\u2500\u2500 mysql     \u251c\u2500\u2500 README.md     \u251c\u2500\u2500 config.yml     \u2514\u2500\u2500 plugin.sh config.yml should all configuration that the plugin is expecting to use. plugin.sh should contain functions; all that are public must be prefixed by the plugin name:  function mysql_on_init() { ensure_files_local_directories &amp;&amp; succeed_because \"Updated fetch structure at $(path_unresolve \"$APP_ROOT\" \"$FETCH_FILES_PATH\")\" }  Plugins may provide the following functions:   Plugins implement hooks which are functions named by: PLUGIN_on_*. To find the hooks available, search the code for plugin_implements and call_plugin. Plugins may define private functions, but they should begin with an underscore. bash function _mysql_get_remote_env() {  case $REMOTE_ENV_ID in  production)    echo 'live' &amp;&amp; return 0    ;;  staging)    echo 'test' &amp;&amp; return 0    ;;  esac  exit_with_failure \"Cannot determine Pantheon environment using $REMOTE_ENV_ID\" }    Error Conditions   Plugins should use fail_because &amp;&amp; succeed_because Plugins should return non-zeros Plugins should not use exit_with_* methods; those are for the controller.   Tests  Add tests to your plugin:   Create PLUGIN.tests.sh, e.g. \"default.tests.sh\" Follow the Cloudy testing framework. Run tests with .\/live_dev_porter tests  ","tags":"","url":"plugins.html"},{"title":"Processors","text":"     The working directory for processors is always the app root.      $ENVIRONMENT_ID will always refer to the source, which in the case of pull is remote, in the case of export local, etc.    To provide feedback to the user the processor should use echo The file must exit with non-zero if it fails. If you wish to indicated the processor was skipped or not applied exit with 255; see examples below. When existing with code 1-254 a default failure message will always be displayed. If the processor echos a message, this default will appear after the response. If the file exists with a zero, there is no default message.   Database Processing   Notice the use of query below; this operates on the database being processed and has all authentication embedded in it. Use this to affect the database. The result of the queries is stored in a file, whose path is written to $query_result; see example using $(cat $query_result).   An example bash processor for a database command:  #!\/usr\/bin\/env bash  #debug \"$COMMAND;\\$COMMAND\" #debug \"$ENVIRONMENT_ID;\\$ENVIRONMENT_ID\" #debug \"$DATABASE_ID;\\$DATABASE_ID\" #debug \"$DATABASE_NAME;\\$DATABASE_NAME\"  # Only do processing when we have a database event. [[ \"$DATABASE_ID\" ]] || exit 255  # Reduce our users to at most 20. if ! query 'DELETE FROM users WHERE uid &gt; 20'; then   echo \"Failed to reduce the user records in $DATABASE_NAME.\"   exit 1 fi  query 'SELECT count(*) FROM users' || exit 1 echo \"$(cat $query_result) total users remain in $DATABASE_NAME\"   File Processing  For file groups having include filter(s), you may create processors, or small files, which can mutate the files comprised by that list.  A use case for this is removing the password from a database credential when the file containing it is pulled locally. This is important if you will be committing a scaffold version of this configuration file containing secrets. The processor might replace the real password with a token such as PASSWORD. This will make the file save for inclusion in source control.  An example bash processor for a file:  #!\/usr\/bin\/env bash  #debug \"$COMMAND;\\$COMMAND\" #debug \"$ENVIRONMENT_ID;\\$ENVIRONMENT_ID\" #debug \"$FILES_GROUP_ID;\\$FILES_GROUP_ID\" #debug \"$FILEPATH;\\$FILEPATH\" #debug \"$SHORTPATH;\\$SHORTPATH\"  # Only do processing when we have a file event. [[ \"$COMMAND\" != \"pull\" ]] &amp;&amp; exit 255 [[ \"$FILES_GROUP_ID\" ]] || exit 255  contents=$(cat \"$FILEPATH\")  if ! [[ \"$contents\" ]]; then   echo \"$SHORTPATH was an empty file.\"   exit 1 fi echo \"Contents approved in $SHORTPATH\"   Here is an example in PHP:  &lt;?php  use AKlump\\LiveDevPorter\\Processors\\EnvTrait; use AKlump\\LiveDevPorter\\Processors\\ProcessorBase; use AKlump\\LiveDevPorter\\Processors\\ProcessorSkippedException;  \/**  * Remove secrets and passwords from install files.  *\/ final class RemoveSecrets extends ProcessorBase {    use EnvTrait;    public function process() {     if (!$this-&gt;loadFile() || 'install' !== $this-&gt;filesGroupId) {       throw new ProcessorSkippedException();     }      if ($this-&gt;getFileInfo()['basename'] == '.env') {       $response = [];       $this-&gt;envReplaceUrlPassword('DATABASE_URL');       $this-&gt;envReplaceUrlPassword('SHAREFILE_URL');       $response[] = \"DATABASE_URL password\";       foreach (['HASH_SALT', 'SHAREFILE_CLIENT_SECRET'] as $variable_name) {         $this-&gt;envReplaceValue($variable_name);         $response[] = $variable_name;       }       $response = sprintf(\"Removed %s from %s.\", implode(', ', $response), $this-&gt;shortpath);     }      $this-&gt;saveFile($new_name);      return $response ?? '';   }  }   ","tags":"","url":"processors.html"},{"title":"Pulling Remote to Local","text":"  ldp pull  This is like git pull, it will copy the remote database and files, depending on your configuration, to your local environment.  Is There Something Like git reset for the Database?  The database dumpfile remains in your local cache after you pull it down. You may reset your local database to that file if you do not need to export and download a fresh copy. To do so, use ldp import and look for and choose the file named pull.sql. This will save you time if it is current enough. ","tags":"","url":"pull.html"},{"title":"Remote Environment","text":"     You should use key-based authentication to avoid password prompts.   config.local.yml  In config.local.php on a developer's machine, that is to say the local perspective the remote environment will usually be either production\/live or staging\/test, e.g.,  local: dev remote: live   However, this is how config.local.php should look on the production server--the remote perspective.  local: live remote:   Default Configuration  environments:   dev:     write_access: true   live:     write_access: false     base_path: \/var\/www\/site.com\/app     ssh: foobar@123.mygreathost.com   Troubleshooting  ldp remote will connect you to the remote environment and cd to the base path. It you do not land in the base path, check ~\/.bashrc and ~\/.bash_profile for the presence of a cd command in there. You will need to comment that out or remove that line if you wish for LDP to land you in the basepath. ","tags":"","url":"remote.html"},{"title":"Sanitation of Vulnerable Data","text":"  This example shows how to setup a processor that will remove the password and secrets from a non-versioned .env file on pull.   Define a file group install, which includes a file called .env. Next, map the file group to your local, e.g., environments.0.files.install (You will need to also map it to the remote, but that's covered elsewhere.) Define a workflow: development Add to that workflow a processor item pointing to a class::method, in this case RemoveSecrets::process Configured the environment to use the development workflow by default on pull Create the processor class::method as .\/live_dev_porter\/processors\/RemoveSecrets.php. Notice the trait and the parent class and study those for more info.   Configuration     This is not a complete configuration, for example the remove environment is missing; just the items needed to illustrate this concept are shown.   .live_dev_porter\/config.yml  file_groups:   install:     include:       - \/.env  workflows:   development:     -       processor: RemoveSecrets::process  environments:   local:     files:       install: install\/default\/scaffold     command_workflows:       pull: development   The Processor File  .\/live_dev_porter\/processors\/RemoveSecrets.php  &lt;?php  use AKlump\\LiveDevPorter\\Processors\\ProcessorFailedException;  class RemoveSecrets extends \\AKlump\\LiveDevPorter\\Processors\\ProcessorBase {    use \\AKlump\\LiveDevPorter\\Processors\\EnvTrait;    public function process() {     if (!$this-&gt;loadFile()       || basename($this-&gt;filepath) != '.env') {       return;     }      $response = [];     $this-&gt;envReplaceUrlPassword('DATABASE_URL');     $response[] = \"DATABASE_URL password\";     foreach (['HASH_SALT', 'SHAREFILE_CLIENT_SECRET'] as $variable_name) {       $this-&gt;envReplaceValue($variable_name);       $response[] = $variable_name;     }     $this-&gt;saveFile();      return sprintf(\"Removed %s from %s.\", implode(', ', $response), $this-&gt;shortpath);   }  }  ","tags":"","url":"sanitation.html"},{"title":"Search Results","text":" ","tags":"","url":"search--results.html"},{"title":"Source Control","text":"  You should add the directory .live_dev_porter to your project's repository, with the exception of the following files; they must be excluded.  .live_dev_porter \u251c\u2500\u2500 .cache \u2514\u2500\u2500 config.local.yml  ","tags":"","url":"source-control.html"},{"title":"Workflows","text":"     Suggestion: Name your workflows using an verb in the imperative, e.g. \"archive\", \"develop\".   GOTCHA     When you pull, the workflow configuration is read from the local environment!   The means you should always keep your workflow config in sync between environments or it starts to blow your mind. ","tags":"","url":"workflows.html"}]};
