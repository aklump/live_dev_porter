# File Groups

File groups are for handling files and directories which are not in source control. For example Drupal-based websites have the concept of a public directory for user uploads. It is for such case that this concept is designed.

Define as many file groups as you want, or none if appropriate. At minimum you must assign an `id` because this is what will be referenced to map the file group to actual file paths later in an `environment` definition.

There are two optional filters which can be used, `include` and `exclude`.  Only one may be used, per file group. For syntax details see the [rsync pattern rules](https://www.man7.org/linux/man-pages/man1/rsync.1.html#INCLUDE/EXCLUDE_PATTERN_RULES). Here is an incomplete summary, covering the main points:

1. If the pattern starts with a `/` then the match is only valid in the top-level directory, otherwise the match is checked recursively in descendent directories.
2. If the pattern ends with a / then it will only match a directory.
3. Using `*` matches any characters stopping at a slash, whereas...
4. Using `**` matches any characters, including the slash.

If the `include` filter is used, for a file or folder to be copied it must be matched by an `include` rule. On the other hand, if the `exclude` filter is used then a file will **not** be copied if it matches an `exclude` rule.

