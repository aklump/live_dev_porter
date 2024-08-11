<!--
id: plugins
tags: ''
-->

# Plugins

> This page needs updating.

1. Plugins are folders saved to the _plugins/_ directory, resembling the following structure.

    ```
    └── mysql
        ├── README.md
        ├── config.yml
        └── plugin.sh
    ```
2. _config.yml_ should all configuration that the plugin is expecting to use.
3. _plugin.sh_ should contain functions; all that are public must be prefixed by the plugin name:

   ```bash
   function mysql_on_init() {
     ensure_files_local_directories && succeed_because "Updated fetch structure at $(path_make_relative "$FETCH_FILES_PATH" "$CLOUDY_BASEPATH")"
   }
   ```
4. Plugins may provide the following functions:
    1. Plugins implement hooks which are functions named by: PLUGIN_on_*.
    2. To find the hooks available, search the code for `plugin_implements` and `call_plugin`.
    3. Plugins may define private functions, but they should begin with an underscore.
       
       ```bash
       function _mysql_get_remote_env() {
         case $REMOTE_ENV_ID in
         production)
           echo 'live' && return 0
           ;;
         staging)
           echo 'test' && return 0
           ;;
         esac
         exit_with_failure "Cannot determine Pantheon environment using $REMOTE_ENV_ID"
       }
        ```

## Error Conditions

1. Plugins should use `fail_because` && `succeed_because`
2. Plugins should return non-zeros
3. Plugins should not use `exit_with_*` methods; those are for the controller.

## Tests

Add tests to your plugin:

1. Create PLUGIN.tests.sh, e.g. "default.tests.sh"
2. Follow the Cloudy testing framework.
3. Run tests with `./live_dev_porter tests`
