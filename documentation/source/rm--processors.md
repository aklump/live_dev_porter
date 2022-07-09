# Processors

## Database Processing

@todo

## File Processing

For file groups having `include` filter(s), you may create _processors_, or small files, which can mutate the files comprised by that list.

A use case for this is removing the password from a database credential when the file containing it is pulled locally. This is important if you will be committing a scaffold version of this configuration file containing secrets. The processor might replace the real password with a token such as `PASSWORD`. This will make the file save for inclusion in source control.

> Processors are not supported when using `exclude` rules in the file group definition.

* To provide feedback to the user the processor should echo a string, which does not contain any line breaks.
* The file must exit with non-zero if it fails.
* When existing non-zero, a default failure message will always be displayed. If the processor echos a message, this default will appear after the response.
* If the file exists with a zero, there is no default message.

_An example bash processor:_

```shell
#!/usr/bin/env bash

filepath=$1
short_path=$2

contents=$(cat "$filepath")

if ! [[ "$contents" ]]; then
  echo "$short_path was an empty file."
  exit 1
fi
echo "Contents approved in $short_path"
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


