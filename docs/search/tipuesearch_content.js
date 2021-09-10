var tipuesearch = {"pages":[{"title":"Changelog","text":"  All notable changes to this project will be documented in this file.  The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.  [Unreleased]   lorem   [N.N.N] - YYYY-MM-DD  Added   lorem   Changed   lorem   Deprecated   lorem   Removed   lorem   Fixed   lorem   Security   lorem  ","tags":"","url":"CHANGELOG.html"},{"title":"Live Dev Porter","text":"    Summary  Simplifies the management and transfer of assets between website environments.  Visit https:\/\/aklump.github.io\/live_dev_porter for full documentation.  Quick Start   Install in your repository root using cloudy pm-install aklump\/live_dev_porter Open bin\/config\/live_dev_porter.yml and modify as needed. Open bin\/config\/live_dev_porter.local.yml and ...; be sure to ignore this file in SCM. Try it out with .\/bin\/live_dev_porter SOME_COMMAND   Requirements  You must have Cloudy installed on your system to install this package.  Installation  The installation script above will generate the following structure where . is your repository root.  . \u251c\u2500\u2500 bin \u2502\u00a0\u00a0 \u251c\u2500\u2500 live_dev_porter -&gt; ..\/opt\/live_dev_porter\/live_dev_porter.sh \u2502\u00a0\u00a0 \u2514\u2500\u2500 config \u2502\u00a0\u00a0     \u251c\u2500\u2500 live_dev_porter.yml \u2502\u00a0\u00a0     \u2514\u2500\u2500 live_dev_porter.local.yml \u251c\u2500\u2500 opt \u2502   \u251c\u2500\u2500 cloudy \u2502   \u2514\u2500\u2500 aklump \u2502       \u2514\u2500\u2500 live_dev_porter \u2514\u2500\u2500 {public web root}   To Update   Update to the latest version from your repo root: cloudy pm-update aklump\/live_dev_porter   Configuration Files  Refer to the file(s) for documentation about configuration options.       Filename   Description   VCS       live_dev_porter.yml   Configuration shared across all server environments: prod, staging, dev   yes     live_dev_porter.local.yml   Configuration overrides for a single environment; not version controlled.   no     Usage   To see all commands use .\/bin\/live_dev_porter   Contributing  If you find this project useful... please consider making a donation. ","tags":"","url":"README.html"},{"title":"Ignore tables altogether","text":"   List the tablenames, one per line in tables.ignore.txt You may use SQL wildcards such as foo_% in your list. Neither the structure, nor the data will appear in the export file.   Ignore data only   List the tablenames, one per line in data.ignore.txt You may use SQL wildcards such as cache_% in your list. The export file will contain structure only.  ","tags":"","url":"export.html"},{"title":"Plugins","text":"   Plugins are folders saved to the plugins\/ directory, resembling the following structure. \u2514\u2500\u2500 pantheon     \u251c\u2500\u2500 README.md     \u251c\u2500\u2500 config.yml     \u2514\u2500\u2500 plugin.sh config.yml should all configuration that the plugin is expecting to use. plugin.sh should contain functions; all that are public must be prefixed by the plugin name: bash function pantheon_init() {   eval $(_get_file_ignore_paths)   for path in \"${ignore_paths[@]}\"; do     if [ ! -f \"$path\" ]; then       touch \"$path\"       succeed_because \"Created: $path\"     fi   done } Plugins must provide the following functions:   ${PLUGIN}_init ${PLUGIN}_authenticate ${PLUGIN}_remote_clear_caches ${PLUGIN}_fetch ${PLUGIN}_reset  Plugins may define private functions, but they should begin with an underscore.  function _get_file_ignore_paths() {   local snippet=$(get_config_as -a 'ignore_paths' 'pantheon.files.ignore')   local find=']=\"'    echo \"${snippet\/\/$find\/$find$CONFIG_DIR\/fetch\/$ENV\/files\/}\" }    Error Conditions   Plugins should use fail_because &amp;&amp; succeed_because Plugins should return non-zeros Plugins should not use exit_with_* methods; those are for the controller.  ","tags":"","url":"plugins.html"},{"title":"Search Results","text":" ","tags":"","url":"search--results.html"}]};
