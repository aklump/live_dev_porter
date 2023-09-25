#!/usr/bin/env bash

# Begin Cloudy Core Bootstrap
export SCRIPT="$s";export ROOT="$r";export WDIR="$PWD";s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;export CLOUDY_ROOT="$(cd -P "$(dirname "$s")" && pwd)";source "$CLOUDY_ROOT/inc/cloudy.api.sh" || exit_with_failure "Missing cloudy/inc/cloudy.api.sh";export CLOUDY_NAME="$(path_filename $SCRIPT)";source "$CLOUDY_ROOT/inc/cloudy.functions.sh" || exit_with_failure "Missing cloudy/inc/cloudy.functions.sh";source "$CLOUDY_ROOT/inc/cloudy.core.sh" || exit_with_failure "Missing cloudy/inc/cloudy.core.sh"
