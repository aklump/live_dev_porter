#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

# Cloudy version 2.0.6

# Begin Cloudy Core Bootstrap
CLOUDY_PACKAGE_CONTROLLER="$s";declare -rx ROOT="$r";declare -rx CLOUDY_START_DIR="$PWD";s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;[[ "$CLOUDY_CORE_DIR" ]] || CLOUDY_CORE_DIR="$(dirname "$s")";declare -rx CLOUDY_CORE_DIR="$(cd "$CLOUDY_CORE_DIR" && pwd)";source "$CLOUDY_CORE_DIR/inc/cloudy.api.sh" || exit_with_failure "Missing cloudy/inc/cloudy.api.sh";source "$CLOUDY_CORE_DIR/inc/cloudy.functions.sh" || exit_with_failure "Missing cloudy/inc/cloudy.functions.sh";source "$CLOUDY_CORE_DIR/inc/cloudy.core.sh" || exit_with_failure "Missing cloudy/inc/cloudy.core.sh";
