<!--
id: environment_roles
tags: ''
-->

# Environment Roles

All public-facing websites have a server that acts as the production or live server. It can be said it plays the _production_ role.

Most sites have a counterpart install, where development takes place; typically on the developer's laptop. This "server" is said to play the _development_ role.

There may be a third installation where new features are reviewed before they are pushed to the live server. This can be the _test_ or _staging_ server, playing the selfsame role.

By these three examples, we have described what is meant by environment roles. When using _Live Dev Porter_, you must define at minimum one role and you may define an unlimited number of roles. The typical, as described above, would be two or three.

The flow of data between the environments is the next topic of discussion. Data, that is files not stored in source control and database content, should **never** flow into the live server. This is because the live server should always be seen as the single source of truth. Therefore it stands to reason that the production role should never be given `write_access` in our configuration.

Whereas data should be able to flow from the live server into either development or test. Therefore these environments are marked as having `write_access`.
