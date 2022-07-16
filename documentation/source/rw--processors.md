# Processors

> The working directory for processors is always the app root.

## Database Processing

* Notice the use of `query` below; this operates on the database being processed and has all authentication embedded in it. Use this to affect the database.
* The result of the queries is stored in a file, whose path is written to `$query_result`; see example using `$(cat $query_result)`.

_An example bash processor for a database command:_

```shell
#!/usr/bin/env bash

#debug "$COMMAND;\$COMMAND"
#debug "$ENVIRONMENT_ID;\$ENVIRONMENT_ID"
#debug "$DATABASE_ID;\$DATABASE_ID"
#debug "$DATABASE_NAME;\$DATABASE_NAME"

# Only do processing when we have a database event.
[[ "$DATABASE_ID" ]] || return 0

# Reduce our users to at most 20.
if ! query 'DELETE FROM users WHERE uid > 20'; then
  echo "Failed to reduce the user records in $DATABASE_NAME."
  exit 1
fi

query 'SELECT count(*) FROM users' || exit 1
echo "$(cat $query_result) total users remain in $DATABASE_NAME"
```

## File Processing

For file groups having `include` filter(s), you may create _processors_, or small files, which can mutate the files comprised by that list.

A use case for this is removing the password from a database credential when the file containing it is pulled locally. This is important if you will be committing a scaffold version of this configuration file containing secrets. The processor might replace the real password with a token such as `PASSWORD`. This will make the file save for inclusion in source control.

> Processors are not supported when using `exclude` rules in the file group definition.

* To provide feedback to the user the processor should echo a string, which does not contain any line breaks.
* The file must exit with non-zero if it fails.
* When existing non-zero, a default failure message will always be displayed. If the processor echos a message, this default will appear after the response.
* If the file exists with a zero, there is no default message.

_An example bash processor for a file:_

```shell
#!/usr/bin/env bash

#debug "$COMMAND;\$COMMAND"
#debug "$ENVIRONMENT_ID;\$ENVIRONMENT_ID"
#debug "$FILES_GROUP_ID;\$FILES_GROUP_ID"
#debug "$FILEPATH;\$FILEPATH"
#debug "$SHORTPATH;\$SHORTPATH"

# Only do processing when we have a file event.
[[ "$FILES_GROUP_ID" ]] || return 0

contents=$(cat "$FILEPATH")

if ! [[ "$contents" ]]; then
  echo "$SHORTPATH was an empty file."
  exit 1
fi
echo "Contents approved in $SHORTPATH"
```

_Same example in PHP:_

```php
<?php
$filepath = $argv[1];
$short_path = $argv[2];

$contents = file_get_contents($filepath);

if ('' == $contents) {
  echo "$short_path was an empty file.";
  exit(1);
}
echo "Contents approved in $short_path";
```


