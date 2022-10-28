# Remote Environment

> You should use key-based authentication to avoid password prompts.

## _config.local.yml_
In _config.local.php_ on a developer's machine, that is to say the _local perspective_ the remote environment will usually be either production/live or staging/test, e.g.,

```yaml
local: dev
remote: live
```

However, this is how _config.local.php_ should look on the production server--the _remote perspective_.

```yaml
local: live
remote:
```

## Default Configuration

```yaml
environments:
  dev:
    write_access: true
  live:
    write_access: false
    base_path: /var/www/site.com/app
    ssh: foobar@123.mygreathost.com
```

## Troubleshooting

`ldp remote` will connect you to the remote environment and `cd` to the base path. It you do not land in the base path, check _~/.bashrc_ and _~/.bash_profile_ for the presence of a `cd` command in there. You will need to comment that out or remove that line if you wish for LDP to land you in the basepath. 


## _.profile_ not loading on login

The app tries to connect as a login shell, but in some cases this may not be possible.  If not then you may find that files such as _.profile_ are not loaded and you're missing some configuration.

See the function `default_on_remote_shell` for more details.

