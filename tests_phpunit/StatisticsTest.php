<?php

use AKlump\LiveDevPorter\Config\RsyncHelper;
use AKlump\LiveDevPorter\Statistics;
use PHPUnit\Framework\TestCase;

/**
 * @group default
 * @covers \AKlump\LiveDevPorter\Config\RsyncHelper
 * @uses \AKlump\LiveDevPorter\Statistics
 */
final class StatisticsTest extends TestCase {

  /**
   * Provides data for testSumDurations.
   */
  public function dataForTestSumDurationsProvider() {
    $tests = [];
    $tests[] = ['1 hour', '1 hour'];
    $tests[] = ['1 hour 17 minutes 3 seconds', '1 hour,17 minutes,3 seconds'];
    $tests[] = ['47 minutes', '30 minutes,16 minutes,60 seconds'];
    $tests[] = ['47 minutes', '30 MINUTES,16 MINUTES,60 SECONDS'];
    $tests[] = ['3 hours 47 minutes 2 seconds', '1h,2h,30min,16min,60sec,2s'];

    return $tests;
  }

  /**
   * @dataProvider dataForTestSumDurationsProvider
   */
  public function testSumDurations($control, $csv) {
    $this->assertSame($control, Statistics::sumDurations($csv));
  }

  public function testFormatSeconds() {
    $this->assertSame('2 hours 1 second', Statistics::formatSeconds(7201));
    $this->assertSame('1 hour 3 minutes 5 seconds', Statistics::formatSeconds(3785));
    $this->assertSame('1 second', Statistics::formatSeconds(1));
    $this->assertSame('7 seconds', Statistics::formatSeconds(7));
    $this->assertSame('1 minute 3 seconds', Statistics::formatSeconds(63));
    $this->assertSame('3 minutes', Statistics::formatSeconds(180));
    $this->assertSame('3 minutes 5 seconds', Statistics::formatSeconds(185));
  }

  public function testFiles() {
    $stats = new Statistics([
      'CACHE_DIR' => __DIR__,
      'COMMAND' => 'pull',
      'TYPE' => Statistics::TYPE_FILE,
      'ID' => 'install',
      'SOURCE' => 'local',
    ]);
    $stats->start();
    $stats->stop();
    $filepath = $stats->getFilepath();
    $data = json_decode(file_get_contents($filepath), TRUE);
    $this->assertIsArray($data['file_groups']['install']['pull']['local']);

    unlink($filepath);
  }

  public function testDatabases() {
    $stats = new Statistics([
      'CACHE_DIR' => __DIR__,
      'COMMAND' => 'pull',
      'TYPE' => Statistics::TYPE_DATABASE,
      'ID' => 'drupal',
      'SOURCE' => 'live',
    ]);
    $stats->start();
    $stats->stop();
    $filepath = $stats->getFilepath();

    $data = json_decode(file_get_contents($filepath), TRUE);
    $this->assertIsArray($data['databases']['drupal']['pull']['live']);

    $stats = new Statistics([
      'CACHE_DIR' => __DIR__,
      'COMMAND' => 'pull',
      'TYPE' => Statistics::TYPE_DATABASE,
      'ID' => 'drupal',
      'SOURCE' => 'test',
    ]);
    $stats->start();
    $stats->stop();
    $data = json_decode(file_get_contents($filepath), TRUE);
    $this->assertIsArray($data['databases']['drupal']['pull']['test']);

    unlink($filepath);
  }

  public function testStopIsGreaterThanStartAndAre8601Dates() {
    $stats = new Statistics([
      'CACHE_DIR' => __DIR__,
      'COMMAND' => 'pull',
      'TYPE' => Statistics::TYPE_DATABASE,
      'ID' => 'drupal',
      'SOURCE' => 'live',
    ]);
    $stats->start();
    sleep(1);
    $stats->stop();
    $filepath = $stats->getFilepath();
    $data = json_decode(file_get_contents($filepath), TRUE);
    $subject = $data['databases']['drupal']['pull']['live'];
    $this->assertNotEmpty($subject['start']);
    $this->assertNotEmpty($subject['stop']);
    $this->assertGreaterThan($subject['start'], $subject['stop']);
    $this->assertInstanceOf(\DateTime::class, date_create_from_format(DATE_ISO8601, $subject['start']));
    $this->assertInstanceOf(\DateTime::class, date_create_from_format(DATE_ISO8601, $subject['stop']));

    $this->assertIsString($stats->getDuration());
    $this->assertSame('1 second', $stats->getDuration());

    unlink($stats->getFilepath());
  }

}
