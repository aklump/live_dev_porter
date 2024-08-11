#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

##
 # @file Define all the variables used by Cloudy Core
 #
 # @export array CLOUDY_FAILURES
 # @export int CLOUDY_EXIT_STATUS
 # @global array CLOUDY_SUCCESSES
 # @global string CLOUDY_INSTALL_TYPE_COMPOSER
 # @global string CLOUDY_INSTALL_TYPE_CORE
 # @global string CLOUDY_INSTALL_TYPE_PM
 # @global string CLOUDY_INSTALL_TYPE_SELF
 # @global string LI
 # @global string LI2
 # @global string LIL
 # @global string LIL2
 ##

export CLOUDY_EXIT_STATUS=0
CLOUDY_INSTALL_TYPE_COMPOSER='composer'
CLOUDY_INSTALL_TYPE_COMPOSER_CREATE_PROJECT='composer_create_project'
CLOUDY_INSTALL_TYPE_COMPOSER_REQUIRE='composer_require'
CLOUDY_INSTALL_TYPE_SCRIPT='cloudy_script'
CLOUDY_INSTALL_TYPE_CORE='cloudy_core'
CLOUDY_INSTALL_TYPE_PM='cloudy_pm'
CLOUDY_INSTALL_TYPE_SELF='self'
CLOUDY_INSTALL_TYPE_CUSTOM='custom'
LI2="│   $LI"
LI="├──"
LIL2="│   $LIL"
LIL="└──"
declare -ax CLOUDY_FAILURES=()
export CLOUDY_FAILURES__SERIALIZED_ARRAY=$(declare -p CLOUDY_FAILURES)
declare -ax CLOUDY_SUCCESSES=()
export CLOUDY_SUCCESSES__SERIALIZED_ARRAY=$(declare -p CLOUDY_SUCCESSES)
