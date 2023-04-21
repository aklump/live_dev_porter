# File Groups

File groups are for handling files and directories which are not in source control. For example Drupal-based websites have the concept of a public directory for user uploads. It is for such case that this concept is designed.

Define as many file groups as you want, or none if appropriate. At minimum you must assign an `id` because this is what will be referenced to map the file group to actual file paths later in an `environment` definition.

There are two optional filters which can be used, `include` and `exclude`. Only one may be used, per file group. For syntax details see the [rsync pattern rules](https://www.man7.org/linux/man-pages/man1/rsync.1.html#INCLUDE/EXCLUDE_PATTERN_RULES). Here is an incomplete summary, covering the main points:

1. If the pattern starts with a `/` then the match is only valid in the top-level directory, otherwise the match is checked recursively in descendent directories.
2. If the pattern ends with a / then it will only match a directory.
3. Using `*` matches any characters stopping at a slash, whereas...
4. Using `**` matches any characters, including the slash.

If the `include` filter is used, for a file or folder to be copied it must be matched by an `include` rule. On the other hand, if the `exclude` filter is used then a file will **not** be copied if it matches an `exclude` rule.

> If a local folder or file exists, yet it appears in a file group's `exclude` rules, it will never be removed by the pull command. You would have to manually remove it.

> If a remote folder or file that was previously pulled gets deleted, it will be automatically be deleted from your local environment the next time you pull.

## Beware of Directory Contents

If you are trying to match a directory, then you are also trying to match it's contents. Make sure to end the line with a '/' or the contents will not be considered. In _Example 1_, `/members/100` will be treated as a file and if it happens to be a directory, the content will never be seen.

However as shown in _Example 2 (A & B)_ using two syntax variations, `/members/100` will be treated as a directory, and it's contents will be excluded/included as appropriate to the directive.  **The ending `/` or `/**` is critical.**

Example 1:

```yaml
file_groups:
  test_content:
    include:
      - /members/100
```

Example 2A:

```yaml
file_groups:
  test_content:
    include:
      - /members/100/
```

Example 2B:

```yaml
file_groups:
  test_content:
    include:
      - /members/100/**
```
