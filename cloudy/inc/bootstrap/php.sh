#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # @file Bootstrap the PHP layer.
 #
 # @return 1 Unknown error.
 # @return 2 If composer vendor cannot be located.
 # @return 3 If pre_config hook returns non-zero
 # @return 4 If PHP cannot be found.
 # @return 5 If $CLOUDY_PHP is not executable.
 # @return 6 If $CLOUDY_PHP path does not appear to be a PHP binary.
 # @return 7 If $CLOUDY_COMPOSER_VENDOR path does not point to an existing directory.
 ##

if [[ "$CLOUDY_COMPOSER_VENDOR" ]]; then
  mode='set'
  # This will be used when this directory is defined at the top of the entry
  # script as relative to that script.  We look to see if it needs to be
  # resolved to an absolute path and then exit.
  if ! path_is_absolute "$CLOUDY_COMPOSER_VENDOR"; then
    CLOUDY_COMPOSER_VENDOR="$(path_make_absolute "$CLOUDY_COMPOSER_VENDOR" "$r")"
  fi
else
  CLOUDY_COMPOSER_VENDOR=$(_cloudy_detect_composer_vendor_by_installation "$CLOUDY_INSTALLED_AS")
  if [ $? -ne 0 ]; then
    write_log_error "Not provided; failed to autodetect \$CLOUDY_COMPOSER_VENDOR"
    fail_because "Cannot find Composer dependencies."
    return 2;
  fi
  mode='autodetected as'
fi

[[ ! -d "$CLOUDY_COMPOSER_VENDOR" ]] && fail_because "\$CLOUDY_COMPOSER_VENDOR is not a directory: $CLOUDY_COMPOSER_VENDOR" && return 7
write_log_debug "\$CLOUDY_COMPOSER_VENDOR $mode \"$CLOUDY_COMPOSER_VENDOR\""

! event_dispatch "pre_config" && fail_because "Non-zero returned by on_pre_config()." && return 3;

if [[ ! -f "$CLOUDY_COMPOSER_VENDOR/autoload.php" ]]; then
  # Attempt to install composer.
  composer_json=$(dirname $CLOUDY_COMPOSER_VENDOR)/composer.json
  composer_lock=$(dirname $CLOUDY_COMPOSER_VENDOR)/composer.lock
  if [[ -f "$composer_json" && ! -f "$composer_lock" ]]; then
    fail_because "You may need to install Composer dependencies."
    fail_because "e.g., (cd "$(dirname "$composer_json")" && composer install)"
  fi
  fail_because "Composer autoloader not found in $CLOUDY_COMPOSER_VENDOR"
  exit 2
fi

export CLOUDY_COMPOSER_VENDOR="$(cd $CLOUDY_COMPOSER_VENDOR && pwd)"

if [[ ! "$CLOUDY_PHP" ]]; then
  CLOUDY_PHP="$(command -v php)"
  [[ ! "$CLOUDY_PHP" ]] && fail_because "\$(command -v php) returned empty" && return 4
fi
[[ ! "$CLOUDY_PHP" ]] && fail_because "\$CLOUDY_PHP cannot be set; PHP not found." && return 4
[[ ! -x "$CLOUDY_PHP" ]] && fail_because "\$CLOUDY_PHP ($CLOUDY_PHP) is not executable" && return 5
php_version=$("$CLOUDY_PHP" -v | head -1 | grep -E "PHP ([0-9.]+)")
[[ ! "$php_version" ]] && fail_because "\$CLOUDY_PHP ($CLOUDY_PHP) does not appear to be a PHP binary; $CLOUDY_PHP -v failed to display PHP version" && return 6

has_failed && return 1
write_log_info "\$CLOUDY_PHP is: $CLOUDY_PHP"
declare -xr CLOUDY_PHP="$CLOUDY_PHP"

##
 # @var PHP_FILE_RUNNER The absolute filepath; see code usage example.
 #
 # By including PHP files with this recommended method you have access to the
 # same variables as in BASH.  You also have access to same-named Cloudy
 # functions such as: fail_because(), succeed_because(), exit_with_failure(),
 # etc.
 #
 # @code
 # . "$PHP_FILE_RUNNER" .../some/file.php <ARG1> <ARG2> ...
 # @endcode
 ##
declare -xr PHP_FILE_RUNNER="$CLOUDY_CORE_DIR/inc/cloudy.php_file_runner.sh"
write_log_debug "\$PHP_FILE_RUNNER is $PHP_FILE_RUNNER"

return 0
