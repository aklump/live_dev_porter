<!--
id: php
tags: ''
-->

# Using PHP in the Codebase

To execute OOP PHP, you must use:

`call_php_class_method "\AKlump\LiveDevPorter\Helpers\FooBarBaz::__invoke(aaron_develop,drupal,drupal,1584,1)"`

Use this pattern when the method returns a value, so that the app will handle errors correctly.

```shell
local result
result=$(call_php_class_method "\AKlump\LiveDevPorter\Helpers\FooBarBaz::__invoke(aaron_develop,drupal,drupal,1584,1)")
[[ $? -ne 0 ]] && fail_because "$result" && return 1
echo "$result"
```

Other, legacy options, not well-documented, try not to use.
`echo_php_class_method`
`call_php_class_method_echo_or_fail "\AKlump\LiveDevPorter\Config\AlphaBravo::build(CACHE_DIR=$CONFIG_DIR/.cache&FOO=123)"`

Notice the arguments must be serialized as CSV or a query string. However the values needn't be wrapped in single/double quotes.

## Code Resources

* _class_method_caller.php_
* `\AKlump\LiveDevPorter\Php\ClassMethodCaller`

## PSR-4 Autoloading

When writing PHP code for your project be aware of the following autoloading rules:

* `AKlump\LiveDevPorter\` is mapped to `/.live_dev_porter/src/`
* `AKlump\LiveDevPorter\Processors\` is mapped to `/.live_dev_porter/processors/` and `/.live_dev_porter/` (as well as `/.live_dev_porter/src/Processors/`)
