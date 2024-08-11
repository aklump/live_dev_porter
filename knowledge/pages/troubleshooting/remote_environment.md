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

## Invalid PHP

└── $CLOUDY_PHP cannot be set; PHP not found.

## Remote export failed: Invalid JSON received

When LDP tries to connect to the remote server, the remote server should send back a JSON string of the result of the connection/operation. If there is a problem on the remote server, such as an error echoes, the the JSON string is corrupted. The return value, that is the corrupt JSON will appear in the log, so you may need to enable it to troubleshoot further.

### Invalid PHP: $CLOUDY_PHP cannot be set; PHP not found.

This may mean that you are explicitly setting `$CLOUDY_PHP` on your remote server, (e.g. in .profile) and that file is not getting source.  I'm not yet sure how to fix this.
