<?php

namespace AKlump\LiveDevPorter\Tests\TestHelpers;


trait TestingFilesTrait {

  public function getCacheDir() {
    return sys_get_temp_dir() . '/ldp/.cache';
  }
}
