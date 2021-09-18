# Remote Environment

The remote environment will usually be either production/live or staging/test.

You should use key-based authentication to avoid password prompts.

## Default Configuration

```yaml
environments:
  production:
    host: 123.mygreathost.com
    user: foobar
    base_path: /var/www/site.com/app
```

## Troubleshooting

`ldp remote` will connect you to the remote environment and `cd` to the base path.  It you do not land in the base path, check _~/.bashrc_ and _~/.bash_profile_ for the presence of a `cd` command in there.  You will need to comment that out or remove that line if you wish for LDP to land you in the basepath. 
