#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # @file Handle $CLOUDY_BASEPATH (resolve, autodetect and validate).
 #
 # @global string $CLOUDY_BASEPATH
 ##

if [[ "$CLOUDY_BASEPATH" ]]; then
  mode='explicitly set to'
  # Due to a set of confusing reasons, we will not allow relative paths for this
  # variable, when it may be explicitly set.  Only absolute paths.
  if ! path_is_absolute "$CLOUDY_BASEPATH"; then
    fail_because "\$CLOUDY_BASEPATH must be absolute when explicitly set."
    fail_because "\"$CLOUDY_BASEPATH\" is relative, and must be absolute."
  fi
else
  mode='autodetected as'
  CLOUDY_BASEPATH="$(_cloudy_detect_basepath "$CLOUDY_INSTALLED_AS")"
  if [[ $? -ne 0 ]]; then
    CLOUDY_BASEPATH=''
    write_log_error "Failed to detect/set \$CLOUDY_BASEPATH"
  fi
fi

if [[ ! "$CLOUDY_BASEPATH" ]]; then
  fail_because "\$CLOUDY_BASEPATH is empty; $(get_title) cannot continue."
  return 3
fi

if [[ ! -d "$CLOUDY_BASEPATH" ]]; then
  fail_because "\$CLOUDY_BASEPATH is not a directory; $(get_title) cannot continue."
  return 3
fi

has_failed && return 1

declare -rx CLOUDY_BASEPATH="$(path_make_canonical "$CLOUDY_BASEPATH")"
write_log_debug "\$CLOUDY_BASEPATH $mode \"$CLOUDY_BASEPATH\""
return 0
