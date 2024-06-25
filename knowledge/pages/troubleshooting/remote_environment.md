<!--
id: remote_environment
tags: ''
-->

# Remote Environment

**THIS PAGE IS A WORK IN PROGRESS**

## `configtest` fails on Live has "*" installed

To fix this you need to ...

## Cannot pull from remote

Try explicitly defining these shell command paths in _config.local.yml_ on the remote server; replace with the correct paths for your server, e.g. `which mysql`, etc.

```shell
shell_commands:
  mysqldump: /usr/local/bin/mysqldump
  mysql: /usr/local/bin/mysql
  php: /usr/local/bin/php
```
