#!/usr/bin/env bash

# @file
# Call a plugin without bootstrapping the entire app.
#

source "$ROOT/scripts/functions.sh";
source "$ROOT/cloudy/inc/cloudy.api.sh";
source "$ROOT/cloudy/inc/cloudy.core.sh";
source "$SOURCE_DIR/database.sh";
for plugin in $PLUGINS ; do
  source "$PLUGIN_DIR/$plugin/$plugin.sh"
done

$FUNCTION $@
