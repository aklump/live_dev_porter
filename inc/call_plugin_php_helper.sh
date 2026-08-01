#!/usr/bin/env bash

# @file
# Call a plugin without bootstrapping the entire app.
#

source "$CLOUDY_CORE_DIR/inc/cloudy.api.sh";
source "$CLOUDY_CORE_DIR/inc/cloudy.functions.sh";
source "$CLOUDY_CORE_DIR/cache/_cached.live_dev_porter.config.sh"
source "$SOURCE_DIR/functions.sh";
source "$SOURCE_DIR/database.sh";
for plugin in $PLUGINS ; do
  source "$PLUGIN_DIR/$plugin/$plugin.sh"
done

$FUNCTION $@
