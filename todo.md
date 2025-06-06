## Critical

## Normal

- `ldp import` should pause before continuing to the processors
- `ldp import` should ask if a backup is desired since you may be trying to replace a broken database and backing that up would be stupid, and would cause the oldest, probably good backup to be deleted.

- bug: in ATS, ldp process create_test_content.sh did not work
- rewrite how remote environment checks work, so we don't get a traffic issue with too many connections too quickly, e.g. ATS Dreamhost
- ldp db, lando not running, then give a message "try starting lando"
- Invalid configuration: when running config test due to json schema invalid.
- remove the `master_dir` idea, treat it as '.'; it will be more readible to just use `master_files`
- need a way to be able to write "Deny from all" to web/.htaccess at the start of ldp pull, then reverse when complete to prevent the Drupal bug that breaks if site is visited during import.

- 
  bug: init fails
  steps:
    - ./vendor/bin/ldp init
    - 'cp: /Users/aklump/Code/Projects/ChapterAndVerse/Numerica/site/app/vendor/aklump/live-dev-porter/init/processors is a directory (not copied).'

- ldp cc did not remove .live_dev_porter/.cache/test/databases/drupal/db.cnf; should createDefaultsFile always remove it? do we remove it on cc hook; we should.

## Remote Time Solution

- [ ] ldp config test against DH servers hits a threshold and gets locked out, so need a way to reduce calls or throttle, or something like that.

```shell
#!/usr/bin/env bash

json=$(echo '{'
echo \"which gzip\":\"$(which gzip)\"
echo ,
echo \"which mysqldump\":\"$(which mysqldump)\"
echo ,
echo \"which mysql\":\"$(which mysql)\"
echo ,
echo \"which ionice\":\"$(which ionice)\"
echo ,
echo \"pwd\":\"$(pwd)\"
echo ,
echo \"-e /home/dh_4zcfny/aurora-timesheet/app/\":\"$([[ -e /home/dh_4zcfny/aurora-timesheet/app/ ]] && echo true || echo false)\"
echo ,
echo \"-e /home/dh_4zcfny/aurora-timesheet/app/web/sites/default/files\":\"$([[ -e /home/dh_4zcfny/aurora-timesheet/app/web/sites/default/files ]] && echo true || echo false)\"
echo ,
echo \"-e /home/dh_4zcfny/aurora-timesheet/app/private/default/files\":\"$([[ -e /home/dh_4zcfny/aurora-timesheet/app/private/default/files ]] && echo true || echo false)\"
echo '}')
echo $json
#[ -e /home/dh_4zcfny/aurora-timesheet/app/ ]
#[ -e /home/dh_4zcfny/aurora-timesheet/app/. ]


```
## Complete
