<!--
id: sanitation
tags: ''
-->

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

## The .env file

```shell
FOO=BAR
HASH_SALT='x4XchzwQ`zk55n24r$\ZQ1P.qkcqZcGEiW7J1-K0jcC9|HC(Csl<;kwxPteegp7aS4iNq~to'
CLIENT_SECRET='TQiGdby59oBv3n$BqOZVxzkKX9ojztZX1hIIK6jIKog\q>iN*IDCbO8b$pbmT1BhMiijIHx4XchzwQ`zk55n24r$\ZQ1P.qkcqZcGEiW7J1-K0jcC9|HC(Csl<;kwxPteegp7aS4iNq~to'
BAR=BAZ
DATABASE_URL=mysql://drupal8:rock$ol1D@database/drupal8
```

After being sanitized:
```shell
FOO=BAR
HASH_SALT=REDACTED
CLIENT_SECRET=REDACTED
BAR=BAZ
DATABASE_URL=mysql://drupal8:PASSWORD@database/drupal8
```

## The Processor File

_./live_dev_porter/processors/RemoveSecrets.php_

```php
class RemoveSecrets extends \AKlump\LiveDevPorter\Processors\ProcessorBase {

  public function process() {
    if (!$this->isWriteableEnvironment() || 'install' !== $this->filesGroupId || !$this->loadFile()) {
      throw new \AKlump\LiveDevPorter\Processors\ProcessorSkippedException();
    }

    // We will apply sanitizing to the ".env" file.
    if ($this->getBasename() === '.env') {
    
      // This argument is passed by reference and is mutated by $redactor.
      $redactor = (new \AKlump\LiveDevPorter\Security\Redactor($this->loadedFile['contents']));
      
      // The default replacement will be used for these two keys.
      $redactor->find(['CLIENT_SECRET', 'HASH_SALT'])->redact();
      
      // A custom "PASSWORD" replacement will be used.
      $redactor->find(['DATABASE_URL'])->replaceWith('PASSWORD')->redact();
      
      // This will contain messages about what, if anything has been redacted.  Or be an empty string if no redaction occurred.
      $message = $redactor->getMessage();
      if (!$message || $this->saveFile() !== FALSE) {
        return $message;
      }

      throw new \Symfony\Component\Process\Exception\ProcessFailedException('Could not save %s', $this->getFilepath());
    }

    throw new \AKlump\LiveDevPorter\Processors\ProcessorSkippedException();
  }

}
```
