#!/usr/bin/env bash

# This processor will export the local database to the live folder so it can be
# imported at a later date without having to go to the live server and
# re-export.  It was designed to be added to a workflow at the very end, after
# one or more sanitizing operations to remove any sensitive information that you
# don't want sitting around in a dumpfile, e.g. user passwords, etc.  Those
# operations would necessarily have to be executed on the local database after
# pulling and importing takes place.

[[ "$DATABASE_ID" ]] || exit 255
[[ "$COMMAND" != "pull" ]] && exit 255

./vendor/bin/ldp export pull.sanitized --workflow=$WORKFLOW_ID --force --dir=$(database_get_directory "$REMOTE_ENV_ID" "$DATABASE_ID") > /dev/null || exit 1
