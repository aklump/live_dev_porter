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

## Composer dependencies require a PHP version ">= ...". You are running ...

If a remote command such as `ldp pull` fails, and you see something like the above in the log `ldp pull -vvv`, then you have a problem with the version of PHP that is being used by Live Dev Porter.

Make sure the correct PHP binary is available in `PATH` for LDP remote commands.

Do not rely only on `.bash_profile` or `.profile`; those may not be loaded for non-interactive remote commands. LDP remote commands rely on the remote shell environment, so place the PHP `PATH` export in `.bashrc`:

```bash
export PATH="/usr/local/php84/bin:$PATH"
```
Then confirm:
```bash
ssh -T user@example.com 'bash -lc "command -v php && php -v"'
```

And then you can load it by doing this inside of .bash_profile

```bash
if [[ -f "$HOME/.bashrc" ]]; then
  . "$HOME/.bashrc"
fi
```
