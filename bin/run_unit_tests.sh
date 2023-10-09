#!/usr/bin/env bash
s="${BASH_SOURCE[0]}";[[ "$s" ]] || s="${(%):-%N}";while [ -h "$s" ];do d="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$d/$s";done;__DIR__=$(cd -P "$(dirname "$s")" && pwd)

cd "$__DIR__/.."

verbose=''
if [[ "${*}" == *'-v'* ]]; then
  verbose='-v'
fi
./vendor/bin/phpswap use 7.3 $verbose './vendor/bin/phpunit -c phpunit.xml'
./vendor/bin/phpswap use 7.4 $verbose './vendor/bin/phpunit -c phpunit.xml'
./vendor/bin/phpswap use 8.0 $verbose './vendor/bin/phpunit -c phpunit.xml'
./vendor/bin/phpswap use 8.1 $verbose './vendor/bin/phpunit -c phpunit.xml'
./vendor/bin/phpswap use 8.2 $verbose './vendor/bin/phpunit -c phpunit.xml'
