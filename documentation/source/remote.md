# Remote Environment

The remote environment will usually be either production/live or staging/test.

You should use key-based authentication to avoid password prompts.

## Default Configuration

```yaml
environments:
  production:
    ssh:
      host: 123.mygreathost.com
      user: foobar
```
