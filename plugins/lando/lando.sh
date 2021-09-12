#!/usr/bin/env bash

function lando_reset_db() {
  local dumpfile="$1"
  local lando_path=$(get_container_path "$dumpfile")
  has_failed && return 1
  lando db-import "$lando_path" || return 1
  return 0
}

function lando_reset_files() {
  return 0
}

# Convert lando database to yml file for config API.
#
function lando_on_compile_config() {

  # TODO Move this to config somehow?
  local service="database"

  local path_to_dynamic_config="$CACHE_DIR/$(path_filename $SCRIPT).lando.config.yml"
  if [ !  -f "$path_to_dynamic_config" ]; then
    json_set "$(lando info -s database --format=json | tail -1)" || return 1
    yaml_clear
    yaml_add_line "environments:"
    yaml_add_line "  dev:"
    yaml_add_line "    database:"
    yaml_add_line "      protocol: tcp"
    yaml_add_line "      host: $(json_get_value '0.external_connection.host')"
    yaml_add_line "      port: $(json_get_value '0.external_connection.port')"
    yaml_add_line "      name: $(json_get_value '0.creds.database')"
    yaml_add_line "      user: $(json_get_value '0.creds.user')"
    yaml_add_line "      pass: $(json_get_value '0.creds.password')"
    yaml_get > "$path_to_dynamic_config"
  fi

  echo "$path_to_dynamic_config"
}

