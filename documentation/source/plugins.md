# Plugins

1. Plugins are folders saved to the _plugins/_ directory, resembling the following structure.
    ```
    └── pantheon
        ├── README.md
        ├── config.yml
        └── plugin.sh
    ```
2. _config.yml_ should all configuration that the plugin is expecting to use.
   1. _plugin.sh_ should contain functions; all that are public must be prefixed by the plugin name:
       ```bash
       function pantheon_init() {
         ensure_files_sync_local_directories && succeed_because "Updated fetch structure at $(path_unresolve "$APP_ROOT" "$FETCH_FILES_PATH")"
       }
       ```
3. Plugins may provide the following functions:
    1. `${PLUGIN}_init`
    2. `${PLUGIN}_authenticate`
    3. `${PLUGIN}_remote_clear_cache`
    4. `${PLUGIN}_fetch`
    5. `${PLUGIN}_reset`
    6. `${PLUGIN}_on_clear_cache`
    7. Plugins may define private functions, but they should begin with an underscore.
       ```bash
       function _get_remote_env() {
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
