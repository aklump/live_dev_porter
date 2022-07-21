# Sanitation of Vulnerable Data

This example shows how to setup a processor that will remove the password and secrets from a non-versioned _.env_ file on `pull`.

1. Define a file group `install`, which includes a file called _.env_.
2. Next, map the file group to your local, e.g., `environments.0.files.install`
3. _(You will need to also map it to the remote, but that's covered elsewhere.)_
4. Define a workflow: `development`
5. Add to that workflow a processor item pointing to a class::method, in this case `RemoveSecrets::process`
6. Configured the environment to use the `development` workflow by default on `pull`
7. Create the processor class::method as _./live_dev_porter/processors/RemoveSecrets.php_. Notice the trait and the parent class and study those for more info.

## Configuration

> This is not a complete configuration, for example the remove environment is missing; just the items needed to illustrate this concept are shown.

_.live_dev_porter/config.yml_

```yaml
file_groups:
  install:
    include:
      - /.env

workflows:
  development:
    -
      processor: RemoveSecrets::process

environments:
  local:
    files:
      install: install/default/scaffold
    command_workflows:
      pull: development
```

## The Processor File

_./live_dev_porter/processors/RemoveSecrets.php_

```php
<?php

use AKlump\LiveDevPorter\Processors\ProcessorFailedException;

class RemoveSecrets extends \AKlump\LiveDevPorter\Processors\ProcessorBase {

  use \AKlump\LiveDevPorter\Processors\EnvTrait;

  public function process() {
    if (!$this->loadFile()
      || basename($this->filepath) != '.env') {
      return;
    }

    $response = [];
    $this->envReplaceUrlPassword('DATABASE_URL');
    $response[] = "DATABASE_URL password";
    foreach (['HASH_SALT', 'SHAREFILE_CLIENT_SECRET'] as $variable_name) {
      $this->envReplaceValue($variable_name);
      $response[] = $variable_name;
    }
    $this->saveFile();

    return sprintf("Removed %s from %s.", implode(', ', $response), $this->shortpath);
  }

}
```
