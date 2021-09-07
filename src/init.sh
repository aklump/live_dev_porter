#!/usr/bin/env bash

# Ensure *.local* files are Git ignored.
git_ignore_file="$CONFIG_DIR/.gitignore"
if [ ! -f "$git_ignore_file" ] || ! grep -q '*.local*' "$git_ignore_file"; then
  echo "*.local*" >> "$git_ignore_file" || fail_because "Could not update $git_ignore_file"
fi
