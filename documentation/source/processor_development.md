# Developing New Processors

You will probably want to test your processors in isolation when developing them, as this will be quicker in most all cases.

Open the processor config environment editor:

```shell
ldp process --config 
```

Set the desired values to be sent to the processor:

```dotenv
COMMAND=pull
LOCAL_ENV_ID=dev
#REMOTE_ENV_ID=
DATABASE_ID=drupal
#DATABASE_NAME=
#FILES_GROUP_ID=
#FILEPATH=
#SHORTPATH=
IS_WRITEABLE_ENVIRONMENT=true
```

Now run the processor. Using `-v` will allow you to see the variables that are being sent.

```shell
ldp process -v delete_users.sh
```
