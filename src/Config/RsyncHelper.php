<?php

namespace AKlump\LiveDevPorter\Config;

class RsyncHelper {

  public function __construct(array $config, array $cloudy_config) {
    $this->config = $cloudy_config;
    $this->dist = $config['CACHE_DIR'];
  }

  public function createFiles() {

    // First delete any cached files created earlier.
    $path = sprintf('%s/rsync_*.txt', $this->dist);
    foreach (glob($path) as $path) {
      unlink($path);
    }

    // Now convert configuration to rsync filter files.
    foreach ($this->config['file_groups'] ?? [] as $group_data) {
      $filter_type = [];
      if (!empty($group_data['include'])) {
        $filter_type[] = 'include';
      }
      if (!empty($group_data['exclude'])) {
        $filter_type[] = 'exclude';
      }
      if (count($filter_type) > 2) {
        throw new \RuntimeException(sprintf('Both "include" and "exclude" may not be used at the same time.  Configuration problem with file group: %s', $group_data['id']));
      }
      $filter_type = array_values($filter_type)[0];

      $ruleset = [];
      if (!empty($group_data[$filter_type])) {
        $path = sprintf('%s/rsync_ruleset.%s.txt', $this->dist, $group_data['id']);
        foreach ($group_data[$filter_type] as $rule) {
          $rules = $this->inflateRule($rule);
          $rules = array_map(function ($item) use ($filter_type) {
            return ($filter_type === 'include' ? '+ ' : '- ') . $item;
          }, $rules);
          $ruleset = array_merge($ruleset, $rules);
        }
      }
      $ruleset[] = ($filter_type === 'include' ? '- *' : '+ *');
      $result = file_put_contents($path, implode(PHP_EOL, $ruleset));
      if (!$result) {
        throw new \RuntimeException(sprintf('Failed to save %s', $path));
      }
    }
  }

  /**
   * @param string $rule
   *
   * @return array
   *
   * @link https://www.man7.org/linux/man-pages/man1/rsync.1.html#INCLUDE/EXCLUDE_PATTERN_RULES
   */
  public static function inflateRule(string $rule): array {
    if (substr_count(rtrim($rule, '/'), '/') < 2) {
      return [$rule];
    }
    $rule = explode('/', $rule);
    for ($i = 0; $i < count($rule) - 1; ++$i) {
      $rule[$i] .= '/';
    }
    $rules = [];
    while ($rule) {
      if (count($rule) !== 1 || $rule[0] !== '/') {
        $rules[] = implode('', $rule);
      }
      array_pop($rule);
    }

    return array_reverse($rules);
  }

}
