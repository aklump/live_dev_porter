#!/usr/bin/env bash

function testPathRelativeToEnvReturnsAppRootWithoutSecondArg() {
  LOCAL_ENV_ID='dev'
  local path=$(path_relative_to_env $LOCAL_ENV_ID)
  assert_same "$path" "$APP_ROOT"
}

function testPathRelativeToEnvReturnsAbsolutePath() {
  LOCAL_ENV_ID='dev'
  local path=$(path_relative_to_env $LOCAL_ENV_ID 'foo/bar')
  assert_same '/' ${path:0:1}
}

function testPathRelativeToEnvFailsWhenEnvironmentMissingConfig() {
  LOCAL_ENV_ID='dev'
  path_relative_to_env bogus 'foo/bar'; assert_exit_status 1
}

function testPathRelativeToEnvFailsWithAbsolute() {
  path_relative_to_env production '/foo/bar'; assert_exit_status 1
}

function testComboPathGetLocalWorksAsExpected() {
  local path

  path="foo/bar"
  assert_same "foo/bar" $(combo_path_get_local "$path")

  path="foo/bar do/re/mi"
  assert_same "foo/bar" $(combo_path_get_local "$path")

  path="foo/bar:do/re/mi"
  assert_same "foo/bar" $(combo_path_get_local "$path")
}

function testComboPathGetRemoteWorksAsExpected() {
  local path

  path="foo/bar"
  assert_same "foo/bar" $(combo_path_get_remote "$path")

  path="foo/bar do/re/mi"
  assert_same "do/re/mi" $(combo_path_get_remote "$path")

  path="foo/bar:do/re/mi"
  assert_same "do/re/mi" $(combo_path_get_remote "$path")
}
