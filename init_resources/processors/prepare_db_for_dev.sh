#!/bin/bash

# @file
#
# Setup local database to be ready for development.
#

# Setup the conditions when this file should be skipped.
[[ "$DATABASE_ID" ]] || exit 255
[[ "$IS_WRITEABLE_ENVIRONMENT" == true ]] || exit 255
[[ "$COMMAND" != "pull" ]] && [[ "$COMMAND" != "import" ]] && exit 255

# Determine where the drush script is and make sure we have one.
if command -v lando > /dev/null; then
  DRUSH="lando drush"
elif command -v drush > /dev/null; then
  DRUSH="drush"
else
  echo "drush is missing" && exit 1
fi

# Change to a context where Drush can know the site.
cd web || exit 1

# Do this first to prevent drush warnings.
$DRUSH cache-rebuild -y >/dev/null

# Sanitize the local database for security.
# @url https://www.drush.org/13.x/commands/sql_sanitize/
! $DRUSH sql-sanitize -y  > /dev/null && echo "Failed to sanitize DB" && exit 1

# Set the passwords for use with Check Pages testing.
$DRUSH upwd uber --password=pass

# Enable/disable modules.
! $DRUSH pm-disable -y securelogin, antispam > /dev/null && echo "Failed to disable production modules." && exit 1
! $DRUSH pm-enable -y reroute_email > /dev/null && echo "Failed to enable development modules." && exit 1

# Finally clear caches and make drupal happy
$DRUSH cache-rebuild -y
exit 0
