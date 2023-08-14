<!--
id: connection_problems
tags: ''
-->

# Trouble Connecting to Remote

## `Too many authentication failures`

1. `mv ~/.ssh/config ~/.ssh/c`
2.

## Restart the Mac

Yes, actually this fixed it for me when nothing else here would.

## Reinstall the SSH key

1. Make sure the value for `Host` in _~/.ssh/config_ on your local matches the remote IP or domain.
2. Make sure the `IdentityFile` exists.
3. Paste the contents of `.pub` of the IndentiyFile to the remote _authorized_keys_
4. Update permissions on remote and local i.e., `chmod 0700 ~/.ssh;chmod 0600 ~/.ssh/*;chmod 0644 ~/.ssh/*.pub`

## Mitigation Options

### Force login using password

1. Add this to the ssh: `-o PreferredAuthentications=password`
2. Enter the password to see if you can connect that way. If so the issue is with the certificate.

