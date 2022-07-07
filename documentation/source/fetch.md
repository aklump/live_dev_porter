# Fetch

## Fetch Files

You may fetch a single group of files like this:

```shell
ldp fetch -f --group=public
```

where the group is the key of the `files` array as shown here:

```yaml
environments:
  dev:
    files:
      public:
        - web/sites/default/files
      private:
        - private/default/files
```

### Exclude Files

Use _.live_dev_porter/fetch/REMOTE_ENV/files/GROUP.ignore.txt_ as you would _.gitignore_ to skip certain files from the fetch.

Example from _public.ignore.txt_
```text
css/
js/
php/
avatars/
design-guide/
stream/
```
