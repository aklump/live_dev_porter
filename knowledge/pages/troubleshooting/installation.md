<!--
id: installation
tags: ''
-->

# Troubleshooting Installation

## Manually delete .live_dev_porter/.cache

This cannot hurt and may fix some issues.

## Failed due to missing configuration; please add "local"

Update to the newest version of Live Dev Porter.

## Failed to bootstrap...Cannot find Composer dependencies

1. Open the log file
2. Search for `CLOUDY_PACKAGE_CONTROLLER`
3. Open that file
4. Add the following line:

```shell
CLOUDY_COMPOSER_VENDOR="/PATH/TO/COMPOSER/vendor"
```


## mysqldump: command not found

https://mysqldump.guru/how-to-install-and-run-mysqldump.html

## Mac

https://github.com/Homebrew/homebrew-core/issues/180498

```shell
brew install mysql-client@8.4
```
