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
if $(which lando > /dev/null); then
  drush_script="lando drush"
elif $(which drush > /dev/null); then
  drush_script="drush"
else
  echo "drush is missing" && exit 1
fi

# Change to a context where Drush can know the site.
cd web || exit 1

# Do this first to prevent drush warnings.
$drush_script cache-rebuild -y >/dev/null

# Sanitize the local database for security.
! $drush_script sql-sanitize -y  > /dev/null && echo "Failed to sanitize DB" && exit 1

# Set the passwords for use with Check Pages testing.
$drush_script upwd uber --password=pass

# Enable/disable modules.
! $drush_script pm-disable -y securelogin, antispam > /dev/null && echo "Failed to disable production modules." && exit 1
! $drush_script pm-enable -y reroute_email > /dev/null && echo "Failed to enable development modules." && exit 1

# Finally clear caches and make drupal happy
$drush_script cache-rebuild -y
exit 0
