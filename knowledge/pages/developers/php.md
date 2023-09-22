# Using PHP in the Codebase

To execute OOP PHP, you must use:

`call_php_class_method "\AKlump\LiveDevPorter\Helpers\FooBarBaz::__invoke(aaron_develop,drupal,drupal,1584,1)"`

Use this pattern when the method is supposed to set a value, so that the app will handle errors.:

`defaults_file=$(call_php_class_method "\AKlump\LiveDevPorter\Database\DatabaseGetDefaultsFile::__invoke($environment_id,$database_id)")
[[ $? -ne 0 ]] && fail_because "$defaults_file" && return 1`

or

`call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Config\AlphaBravo::build(CACHE_DIR=$CONFIG_DIR/.cache&FOO=123)"`

Notice the arguments must be serialized as CSV or a query string. However the values needn't be wrapped in single/double quotes.

## Code Resources

* _class_method_caller.php_
* `\AKlump\LiveDevPorter\Php\ClassMethodCaller`

