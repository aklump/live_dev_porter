<?php

namespace AKlump\LiveDevPorter\Tests;

use AKlump\LiveDevPorter\Config\RuntimeConfig;
use AKlump\LiveDevPorter\Config\RuntimeConfigInterface;
use AKlump\LiveDevPorter\Php\ClassMethodCaller;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Php\ClassMethodCaller
 */
class ClassMethodCallerTest extends TestCase {

  public function testExpressConstants() {
    $args = [
      'FOO',
      'BAR',
      'BAZ',
      '\AKlump\LiveDevPorter\Tests\Testable::MONTH',
      '\AKlump\LiveDevPorter\Tests\Testable::YEAR',
    ];
    define('FOO', 1);
    define('BAR', 2);
    define('BAZ', 3);
    $result = (ClassMethodCaller::expressConstants($args));
    $this->assertSame([1, 2, 3, 'Sep', 2023], $result);
  }

  public function dataFordecodeClassArgsProvider() {
    $tests = [];
    $tests[] = [
      'do=1',
      [['do' => '1']],
    ];
    $tests[] = [
      'do=1&re=2',
      [['do' => '1', 're' => '2']],
    ];
    $tests[] = [
      'do',
      ['do'],
    ];
    $tests[] = [
      'do,re',
      ['do', 're'],
    ];
    $tests[] = [
      'do,1,2.5',
      ['do', 1, 2.5],
    ];

    return $tests;
  }

  /**
   * @dataProvider dataFordecodeClassArgsProvider
   */
  public function testDecodeClassArgs(string $serialized, array $expected) {
    $this->assertSame($expected, ClassMethodCaller::decodeClassArgs($serialized));
  }

  public function testWithPublicMethodConstructorReceivesConfigLikeArguments() {
    $cloudy_config = new RuntimeConfig(['squirrel' => 'scared']);
    $result = (new ClassMethodCaller($cloudy_config))(
      Testable::class,
      'bravo',
      [['autoload' => '/path/foo', 'name' => 'lorem']],
      []
    );
    $this->assertCount(2, $result['constructor']);

    $this->assertSame('/path/foo', $result['constructor'][0]['autoload']);
    $this->assertSame('lorem', $result['constructor'][0]['name']);

    $this->assertInstanceOf(RuntimeConfigInterface::class, $result['constructor'][1]);
    $this->assertSame($cloudy_config, $result['constructor'][1]);
  }

  public function testWithPublicMethodConstructorReceivesAllArguments() {
    $cloudy_config = new RuntimeConfig(['squirrel' => 'scared']);
    $result = (new ClassMethodCaller($cloudy_config))(
      Testable::class,
      'bravo',
      ['do', 're', 'mi'],
      []
    );
    $this->assertCount(4, $result['constructor']);

    $this->assertSame('do', $result['constructor'][0]);
    $this->assertSame('re', $result['constructor'][1]);
    $this->assertSame('mi', $result['constructor'][2]);

    $this->assertInstanceOf(RuntimeConfigInterface::class, $result['constructor'][3]);
    $this->assertSame($cloudy_config, $result['constructor'][3]);
  }

  public function testInvokeWithInvokeMethodConstructorReceivesConfigMethodReceivesArgs() {
    $cloudy_config = new RuntimeConfig(['squirrel' => 'scared']);
    $result = (new ClassMethodCaller($cloudy_config))(
      Testable::class,
      '__invoke',
      ['do', 're', 'mi'],
      []
    );
    $this->assertSame($cloudy_config, $result['constructor'][0]);
    $this->assertCount(3, $result['method']);
    $this->assertSame('do', $result['method'][0]);
    $this->assertSame('re', $result['method'][1]);
    $this->assertSame('mi', $result['method'][2]);
  }

  // (array $config, RuntimeConfigInterface $cloudy_config) {

  /**
   * For static methods, the constructor will receive nothing:  the method will
   * receive two arguments the first is an array with the args, the second is
   * and instance of \AKlump\LiveDevPorter\Config\RuntimeConfigInterface.
   *
   * @return void
   */
  public function testInvokeWithStaticSendsOnlyToTheMethod() {
    $cloudy_config = new RuntimeConfig(['squirrel' => 'scared']);
    $result = (new ClassMethodCaller($cloudy_config))(
      Testable::class,
      'alpha',
      ['do', 're', 'mi'],
      ['foo', 'bar']
    );

    $this->assertNull($result['constructor']);

    $this->assertIsArray($result['method']);
    $this->assertCount(2, $result['method']);
    $this->assertSame('foo', $result['method'][0]);
    $this->assertSame('bar', $result['method'][1]);
  }

}

class Testable {

  const YEAR = 2023;

  const MONTH = 'Sep';

  private $constructorArgs;

  public function __construct() {
    $this->constructorArgs = func_get_args();
  }

  public static function alpha() {
    return [
      'constructor' => NULL,
      'method' => func_get_args(),
    ];
  }

  public function bravo() {
    return [
      'constructor' => $this->constructorArgs,
      'method' => func_get_args(),
    ];
  }

  public function __invoke() {
    return [
      'constructor' => $this->constructorArgs,
      'method' => func_get_args(),
    ];
  }

}
