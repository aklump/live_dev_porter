# Developing New Processors

You will probably want to test your processors in isolation when developing them, as this will be quicker in most all cases. Here's how:

_.devenv_
```dotenv
LOCAL_ENV_ID=dev
DATABASE_ID=drupal
COMMAND=pull
IS_WRITEABLE_ENVIRONMENT=true
```

```shell
ldp process delete_users.sh --env=.devenv
```

1. Create a file of any name wherein you can place your test variable values, e.g. _.devenv_
2. Call the `process` command with the processor basename as the argument and the path to the dotenv file you created.
