# Plugins

1. Plugins are folders saved to the _plugins/_ directory, resembling the following structure.
    ```
    └── pantheon
        ├── README.md
        ├── config.yml
        └── plugin.sh
    ```
2. _config.yml_ should all configuration that the plugin is expecting to use.
3. _plugin.sh_ should contain functions; all that are public must be prefixed by the plugin name:
    ```bash
    function pantheon_init() {
      eval $(_get_file_ignore_paths)
      for path in "${ignore_paths[@]}"; do
        if [ ! -f "$path" ]; then
          touch "$path"
          succeed_because "Created: $path"
        fi
      done
    } 
    ```
4. Plugins may provide the following functions:
    1. `${PLUGIN}_init`
    1. `${PLUGIN}_authenticate`
    1. `${PLUGIN}_remote_clear_cache`
    1. `${PLUGIN}_fetch`
    1. `${PLUGIN}_reset`
    1. `${PLUGIN}_on_clear_cache`
5. Plugins may define private functions, but they should begin with an underscore.
    ```bash
    function _get_file_ignore_paths() {
      local snippet=$(get_config_as -a 'ignore_paths' 'pantheon.files.ignore')
      local find=']="'
    
      echo "${snippet//$find/$find$CONFIG_DIR/fetch/$ENV/files/}"
    }
    ```

## Error Conditions

1. Plugins should use `fail_because` && `succeed_because`
2. Plugins should return non-zeros
3. Plugins should not use `exit_with_*` methods; those are for the controller.
