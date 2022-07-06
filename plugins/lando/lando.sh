#!/usr/bin/env bash

function lando_on_boot() {
  [ -e "$APP_ROOT/.lando.yml" ] || return 0
  local name=$(grep name: < "$APP_ROOT/.lando.yml")
  LANDO_APP_NAME=${name/name: /}
}

function lando_configtest() {
  local running
  local assert

  # Assert we have a lando app name.
  assert="Lando app identified as \"$LANDO_APP_NAME\"."
  if [[ ! "$LANDO_APP_NAME" ]]; then
    echo_fail "$assert" && fail
  else
    echo_pass "$assert"
  fi

  # Assert that app is running.
  local message="\"$LANDO_APP_NAME\" is running"
  if [[ ! "$LANDO_APP_NAME" ]] || [[ "$(lando list --app $LANDO_APP_NAME)" == "[]" ]]; then
    echo_fail "$message" && fail
  else
    echo_pass "$message"
  fi
}

function lando_reset_db() {
  local dumpfile="$1"
  local lando_path=$(get_container_path "$dumpfile")
  has_failed && return 1
  lando db-import "$lando_path" || return 1
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
    yaml_add_line "      password: $(json_get_value '0.creds.password')"
    yaml_get > "$path_to_dynamic_config"
  fi

  echo "$path_to_dynamic_config"
}

