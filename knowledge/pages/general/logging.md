<!--
id: logging
tags: ''
-->

# Enable Logging

In order to troubleshoot, you may want to enable file logging. Follow these steps:

1. In the vendor directory, find the controller file, e.g. _vendor/aklump/live-dev-porter/live_dev_porter.sh_
2. Uncomment the line containing `#LOGFILE="live_dev_porter.core.log"`
3. Execute any commands and review the logfile. The file will be written to the same directory as the controller file, e.g. _vendor/aklump/live-dev-porter/_
4. To disable logging, just re-comment that same line, or, it will be disabled if the composer package is updated as the controller file will be overwritten.
