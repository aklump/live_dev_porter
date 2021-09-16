#!/usr/bin/env bash

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
