<?php

namespace AKlump\LiveDevPorter;

/**
 * Get the local timezone per the system
 *
 * @url https://www.baeldung.com/linux/current-system-time-zone
 */
class LocalTimezone {

  public static function get(): \DateTimeZone {
    $system_timezone_name = trim(exec('echo $TZ'));
    if (!$system_timezone_name) {
      $system_timezone_name = exec('date +%Z');
      $system_timezone_name = timezone_name_from_abbr($system_timezone_name);
    }
    $system_timezone = timezone_open($system_timezone_name);

    return $system_timezone;
  }
}
