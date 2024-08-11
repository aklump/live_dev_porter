<!--
id: remote_install_alt
tags: ''
-->

# Alternative Remote Installations

**THIS PAGE IS A WORK IN PROGRESS**

## Install with Composer in Isolated Directory

In some cases you must install Live Dev Porter as a standalone app on the remote server in order to connect from your development server. These alternative instructions show you how.

**This doesn't allow composer update for LDP, so maybe the lower version is better to work out**

1. `composer create-project aklump/live-dev-porter ldp`
2. Open _ldp/live_dev_porter.core.yml_   
3. Change `config_path_base: ../../..` to `config_path_base: .`
4. `./ldp/live_dev_porter.sh init`
4. `./ldp/live_dev_porter.sh cc` ?
5. `./ldp/live_dev_porter.sh config` ... proceed with configuration

---
To install Live Dev Porter on a remote server without using source control do the following.

1. On the remote server create a folder _live_dev_porter_ as a sibling to your webroot.
2. `cd` into that directory
3. composer require {{ composer.require }}
4. Open _.live\_dev\_porter/config.yml_ and add ONLY the `live' environment and any workflows it uses from your local file.
5. Edit _config.local.yml_ to include only include `local: live`
6. Edit the remote `$PATH` to include _...live_dev_porter/vendor/bin_
7. Configure the correct database connection, probably `mysql`... you do not need to separate the `password` out; include it in _config.yml_

## Use Git Clone

1. `git clone https://github.com/aklump/live_dev_porter.git`
2. `cd live_dev_porter`
3. `composer install`
4. `cd bin && pwd` and copy to clipboard
5. Add the clipboard contents to the `$PATH` variable in (probably) _.profile_
6. Reload the profile, e.g. `. ~/.profile`
7. Open _live_dev_porter.sh_ and change `CLOUDY_COMPOSER_VENDOR` to:
    ```shell
    CLOUDY_COMPOSER_VENDOR="vendor"
    ```
8. Open _live_dev_porter.core.yml_ and change `config_path_base` to:
    ```shell
    config_path_base: .
    ```
9. `cd .. && ln -s live_dev_porter/live_dev_porter.sh .`
10. `cd vendor/bin`
11. `ln ../../live_dev_porter/bin/ldp ldp`
12. `ldp cc`
13. ldp configtest
