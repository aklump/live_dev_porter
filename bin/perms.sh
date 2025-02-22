#!/usr/bin/env bash

s="${BASH_SOURCE[0]}";[[ "$s" ]] || s="${(%):-%N}";while [ -h "$s" ];do d="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$d/$s";done;__DIR__=$(cd -P "$(dirname "$s")" && pwd)

chmod u+x $__DIR__/../live_dev_porter.sh
chmod u+x $__DIR__/bind_book.sh
chmod u+x $__DIR__/ldp
chmod u+x $__DIR__/run_multi_php_unit_tests.sh
chmod u+x $__DIR__/run_unit_tests.sh
chmod u+x $__DIR__/../vendor/bin/phpunit
