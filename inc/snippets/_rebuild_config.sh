call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Config\RsyncHelper::onRebuildConfig" "CACHE_DIR=$CACHE_DIR"
call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Config\SchemaBuilder::onRebuildConfig" "CACHE_DIR=$CACHE_DIR&ROOT=$ROOT"
call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Config\Validator::validate" "CACHE_DIR=$CACHE_DIR"
for plugin in "${ACTIVE_PLUGINS[@]}"; do
  plugin_implements "$plugin" rebuild_config && call_plugin "$plugin" rebuild_config
done
