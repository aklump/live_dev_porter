# Files

File sync uses one or more file "groups", e.g. `files_sync.public`.

If the local and remote paths are the same then do like this:

```yaml
files_sync:
  public:
    - web/sites/default/files
```

If the local and remote paths are different then use this pattern `LOCAL:REMOTE`, e.g.,

```yaml
files_sync:
  public:
    - web/sites/default/files:/files
```
