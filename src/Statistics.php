<?php

namespace AKlump\LiveDevPorter;

use Jasny\DotKey;

final class Statistics {

  const TYPE_DATABASE = 1;

  const TYPE_FILE = 2;

  /**
   * @var string
   */
  private $command;

  /**
   * @var int
   */
  private $type;

  /**
   * @var string
   */
  private $id;

  /**
   * @var string
   */
  private $source;

  public function __construct(array $config) {
    $this->filepath = $config['CACHE_DIR'] . '/statistics.json';
    $this->command = $config['COMMAND'];
    $this->type = intval($config['TYPE']);
    $this->id = $config['ID'];

    // The reason is that we want gz and not gz to track as the same source.
    $this->source = preg_replace('/\.sql\.gz$/', '.sql', $config['SOURCE']);
    // ... also dots in the value break the DotKey dot-notation.
    $this->source = str_replace('.', '_', $this->source);
  }

  /**
   * Record the starting of the command.
   *
   * @return void
   */
  public function start() {
    $this->load()
      ->set('start', date(DATE_ISO8601))
      ->set('stop', NULL)
      // Do not empty duration here; long answer, but just don't.
      ->save();
  }

  /**
   * Record the stopping of the command.
   *
   * @return void
   */
  public function stop() {
    $start = $this->load()->get('start');
    $stop = date(DATE_ISO8601);
    $start = date_create_from_format(DATE_ISO8601, $start);
    $diff = date_diff(date_create_from_format(DATE_ISO8601, $stop), $start);
    $duration = $this->formatSeconds($diff->format('%i') * 60 + $diff->format('%s'));
    $this
      ->set('stop', $stop)
      ->set('duration', $duration)
      ->save();
  }

  /**
   * Get the duration of the command (post stop).
   *
   * @return string
   *   A string like this "1m45s"
   */
  public function getDuration(): string {
    return strval($this->load()->get('duration'));
  }

  /**
   * @param string $csv
   *   A CSV array of output from ::getDuration to be added together
   *
   * @return string
   *   The sum in the same format as getDuration()
   */
  public static function sumDurations(string $csv): string {
    $sum = array_sum(array_map(function ($item) {
      preg_match('/(\d+)\s*m/i', $item, $min);
      preg_match('/(\d+)\s*s/i', $item, $sec);

      return ($min[1] ?? 0) * 60 + ($sec[1] ?? 0);
    }, explode(',', $csv)));

    return self::formatSeconds($sum);
  }

  /**
   * Format seconds to an nice string.
   *
   * @param int $seconds
   *
   * @return string
   *   A string, e.g. 4 min 3 sec
   *
   * // TODO Move this to Cloudy?
   */
  public static function formatSeconds(int $seconds): string {
    $min = floor($seconds / 60);
    $seconds -= $min * 60;
    if ($min) {
      if ($seconds) {
        return sprintf('%d min %d sec', $min, $seconds);
      }

      return sprintf('%d min', $min);
    }

    return sprintf('%d sec', $seconds);
  }

  /**
   * Get the path to the raw storage.
   *
   * @return string
   *   The filepath to the raw data.
   */
  public function getFilepath(): string {
    return $this->filepath;
  }

  private function load(): Statistics {
    if (!file_exists($this->filepath)) {
      $this->data = [];
    }
    else {
      $this->data = json_decode(file_get_contents($this->filepath), TRUE) ?? [];
    }

    return $this;
  }

  private function set($key, $value): Statistics {
    if ($this->type === Statistics::TYPE_DATABASE) {
      $type = 'databases';
    }
    elseif ($this->type === Statistics::TYPE_FILE) {
      $type = 'file_groups';
    }
    else {
      $type = 'extra';
    }

    $this->data = DotKey::on($this->data)->put(implode('.', [
      $type,
      $this->id,
      $this->command,
      $this->source,
      $key,
    ]), $value);

    return $this;
  }

  private function get($key) {
    if ($this->type === Statistics::TYPE_DATABASE) {
      $type = 'databases';
    }
    elseif ($this->type === Statistics::TYPE_FILE) {
      $type = 'file_groups';
    }
    else {
      $type = 'extra';
    }

    return DotKey::on($this->data)->get(implode('.', [
      $type,
      $this->id,
      $this->command,
      $this->source,
      $key,
    ]));
  }

  /**
   * @return false|int
   */
  private function save() {
    return file_put_contents($this->filepath, json_encode($this->data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
  }


}
