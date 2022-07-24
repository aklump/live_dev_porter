#!/bin/bash

# @file
#
# Setup local database to be ready for development.
#

# Setup the conditions when this file should be executed.
[[ "$DATABASE_ID" ]] || exit 255
[[ "$IS_WRITEABLE_ENVIRONMENT" == true ]] || exit 255
[[ "$COMMAND" != "pull" ]] && [[ "$COMMAND" != "import" ]] && exit 255
$(which lando > /dev/null) || exit 255

# Change to a context where Drush can know the site.
cd web || return 1

# Do this first to prevent drush warnings.
lando drush cache-rebuild -y >/dev/null

# Sanitize the local database for security.
! lando drush sql-sanitize -y  > /dev/null && echo "Failed to sanitize DB" && exit 1

# Set the passwords for use with Check Pages testing.
lando drush upwd uber --password=pass

# Enable/disable modules.
! lando drush pm-disable -y securelogin, antispam > /dev/null && echo "Failed to disable production modules." && exit 1
! lando drush pm-enable -y reroute_email > /dev/null && echo "Failed to enable development modules." && exit 1

# Finally clear caches and make drupal happy
lando drush cache-rebuild -y
exit 0
