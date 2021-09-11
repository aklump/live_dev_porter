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
