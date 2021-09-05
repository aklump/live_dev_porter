# Plugins

1. Plugins are folders saved to the _plugins/_ directory, resembling the following structure.
    ```
    └── pantheon
        ├── README.md
        └── plugin.sh
    ```
2. _plugin.sh_ should contain functions; all that are public must be prefixed by the plugin name:
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
3. Plugins must provide the following functions:
    1. `${PLUGIN}_init`
    1. `${PLUGIN}_authenticate`
    1. `${PLUGIN}_remote_clear_caches`
    1. `${PLUGIN}_fetch`
    1. `${PLUGIN}_reset`
4. Plugins may define private functions, but they should begin with an underscore.
    ```bash
    function _get_file_ignore_paths() {
      local snippet=$(get_config_as -a 'ignore_paths' 'pantheon.files.ignore')
      local find=']="'
    
      echo "${snippet//$find/$find$CONFIG_DIR/fetch/$ENV/files/}"
    }
    ```
