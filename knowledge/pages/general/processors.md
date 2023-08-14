<!--
id: processors
tags: ''
-->

# Processors

> The working directory for processors is always the app root.

> `$ENVIRONMENT_ID` will always refer to the source, which in the case of pull is remote, in the case of export local, etc.

* To provide feedback to the user the processor should use echo
* The file must exit with non-zero if it fails.
* If you wish to indicated the processor was skipped or not applied exit with 255; see examples below.
* When existing with code 1-254 a default failure message will always be displayed. If the processor echos a message, this default will appear after the response.
* If the file exits with a zero, there is no default message.

## Database Processing

* Notice the use of `query` below; this operates on the database being processed and has all authentication embedded in it. Use this to affect the database.
* The result of the queries is stored in a file, whose path is written to `$query_result`; see example using `$(cat $query_result)`.
* Database preprocessing is available for `push` and `pull` operations only at this time.

_An example bash processor for a database command:_

```shell
#!/usr/bin/env bash

# Only do processing when we have a database event.
[[ "$DATABASE_ID" ]] || exit 255

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

_An example bash processor for a file:_

```shell
#!/usr/bin/env bash

# Only do processing when we have a file event.
[[ "$COMMAND" != "pull" ]] && exit 255
[[ "$FILES_GROUP_ID" ]] || exit 255

contents=$(cat "$FILEPATH")

if ! [[ "$contents" ]]; then
  echo "$SHORTPATH was an empty file."
  exit 1
fi
echo "Contents approved in $SHORTPATH"
```

When creating PHP processors, you should make all methods private, except those that are to be considered callable as a processor.  The processor indexing method will expose all public methods in the options menu.

_Here is an example in PHP:_

```php
<?php

use AKlump\LiveDevPorter\Processors\EnvTrait;
use AKlump\LiveDevPorter\Processors\ProcessorBase;
use AKlump\LiveDevPorter\Processors\ProcessorSkippedException;

/**
 * Remove secrets and passwords from install files.
 */
final class RemoveSecrets extends ProcessorBase {

  use EnvTrait;

  public function process() {
    if ($this->getEnv('LOCAL_ENV_ID') !== 'dev') {
      throw new ProcessorSkippedException('Local environment is not "dev"');
    }
    if (!$this->loadFile() || 'install' !== $this->filesGroupId) {
      throw new ProcessorSkippedException('Files group is not "install".');
    }

    if ($this->getFileInfo()['basename'] == '.env') {
      $response = [];
      $this->envReplaceUrlPassword('DATABASE_URL');
      $this->envReplaceUrlPassword('SHAREFILE_URL');
      $response[] = "DATABASE_URL password";
      foreach (['HASH_SALT', 'SHAREFILE_CLIENT_SECRET'] as $variable_name) {
        $this->envReplaceValue($variable_name);
        $response[] = $variable_name;
      }
      $response = sprintf("Removed %s from %s.", implode(', ', $response), $this->shortpath);
    }

    $this->saveFile($new_name);

    return $response ?? '';
  }

}

```


