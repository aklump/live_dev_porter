#!/usr/bin/env bash

function testGetRemoteEnvTranslatesAsExpected() {
  assert_same live $(REMOTE_ENV_ID=production; _get_remote_env 'production')
  assert_same test $(REMOTE_ENV_ID=staging; _get_remote_env 'production')
  $(REMOTE_ENV_ID=foo; _get_remote_env > /dev/null); assert_exit_status 1
}
