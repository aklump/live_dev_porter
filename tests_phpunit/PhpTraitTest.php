<?php

use AKlump\LiveDevPorter\Processors\PhpTrait;
use AKlump\LiveDevPorter\Processors\ProcessorFailedException;
use PHPUnit\Framework\TestCase;

/**
 * @covers \AKlump\LiveDevPorter\Processors\PhpTrait
 */
final class PhpTraitTest extends TestCase {

  /**
   * Provides data for testVariantsOfCodeFormat.
   */
  public function dataForTestVariantsOfCodeFormatProvider() {
    $tests = [];
    $tests[] = ["\$databases = [\n  'default' => [\n    'default' => [\n      'password' => 'd9_f2WaBYaA@*BWfcqrW',\n    ],\n  ],\n];"];
    $tests[] = ["\$databases = array(\n  'default' => array(\n    'default' => array(\n      'password' => 'd9_f2WaBYaA@*BWfcqrW',\n    ),\n  ),\n);"];
    $tests[] = ["\$databases[\"default\"][\"default\"][\"password\"] = \"%s\""];
    $tests[] = ["\$databases['default']['default']['password'] = '%s'"];

    return $tests;
  }

  /**
   * @dataProvider dataForTestVariantsOfCodeFormatProvider
   */
  public function testVariantsOfCodeFormat($variant) {
    $password = 'd9_f2WaBYaA@*BWfcqrW';
    $variant = sprintf($variant, $password);
    $obj = new PhpTraitTestable();
    $obj->loadedFile['contents'] = "<?php\n\n\$config['system.logging']['error_level'] = ERROR_REPORTING_DISPLAY_ALL;\n$variant;\n";

    $this->assertStringContainsString($password, $obj->loadedFile['contents']);
    $obj->phpReplaceValue('databases.default.default.password');
    $this->assertStringNotContainsString($password, $obj->loadedFile['contents']);
  }

  public function testNoReplacementThrowsException() {
    $this->expectException(ProcessorFailedException::class);
    $obj = new PhpTraitTestable();
    $obj->loadedFile['contents'] = "<?php \$a = 123;\n";
    $obj->phpReplaceValue("\$databases['default']['default']['password']");
  }

  public function testPhpReplaceValueWorksAsExpectedOnMultiDots() {
    $password = 'd9_f2WaBYaA@*BWfcqrW';
    $obj = new PhpTraitTestable();
    $obj->loadedFile['contents'] = "<?php

\$config['system.logging']['error_level'] = ERROR_REPORTING_DISPLAY_ALL;
\$config['front_end_components.settings']['validate'] = TRUE;
\$config['design_guide.settings']['free_access'] = TRUE;

# Do not remove this, otherwise drush will connect to the wrong db.  See  GOP-3318: Migrate TEST.globalonenessproject.org to 74.121.196.117
\$databases['default']['default']['database'] = 'foo_test';
\$databases['default']['default']['username'] = 'foo_test';
\$databases['default']['default']['password'] = '$password';\n";

    $this->assertStringContainsString($password, $obj->loadedFile['contents']);
    $obj->phpReplaceValue('databases.default.default.password');
    $this->assertStringNotContainsString($password, $obj->loadedFile['contents']);
  }

}

final class PhpTraitTestable {

  use PhpTrait;

  public $loadedFile = [];

  protected function validateFileIsLoaded() {

  }

}
