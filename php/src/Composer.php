<?php

namespace AKlump\LiveDevPorter;

use Composer\Script\Event;

class Composer {

  public static function uninstall(Event $event) {
    if ($event->getIO()->isInteractive()) {
      $event->getIO()
        ->write("The folder .live_dev_porter, with your configuration must be manually removed, if you wish.");
    }
  }

}
