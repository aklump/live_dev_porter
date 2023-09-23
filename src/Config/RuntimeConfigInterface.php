<?php

namespace AKlump\LiveDevPorter\Config;

interface RuntimeConfigInterface {

  public function get(string $dot_path);

  public function all(): array;

}
