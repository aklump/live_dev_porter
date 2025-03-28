<!--
id: readme
title: 'Start Here'
tags: ''
-->

# Live Dev Porter

![live_dev_porter](../../images/live-dev-porter.jpg)

## Summary

Simplifies the management and transfer of assets between website environments.

**Visit <https://aklump.github.io/live_dev_porter> for full documentation.**

{{ composer.install|raw }}

## Quick Start

2. Ensure execute permissions: `chmod u+x ./vendor/bin/ldp`
3. Initialize your project using `./vendor/bin/ldp init`
4. (To migrate from Loft Deploy jump below...)
5. Open _.live\_dev\_porter/config.yml_ and modify as needed.
6. **Ensure _.live\_dev\_porter/config.local.yml_ is ignored by your SCM!**
7. Open _.live\_dev\_porter/config.local.yml_ and define the correct `local` and `remote` environment IDs as defined in _config.yml_.
8. Run `./vendor/bin/ldp configtest` and work through any failed tests.

### Migrating from Loft Deploy?

1. `rm .live_dev_porter/config*`
2. `./vendor/bin/ldp config-migrate .loft_deploy`
3. Rewrite any hooks as processors.
4. Return to where you left off above.

### Optional Shorthand `ldp` instead of `./vendor/bin/ldp`

#### Option A: `$PATH`

_This option has the advantage that any other composer binary in your project will be executable as well._

1. Add _/path/to/project/root/vendor/bin_ to your `$PATH`.

_~/.bash_profile_

```shell
PATH="/path/to/project/root/vendor/bin/ldp:$PATH"
```

#### Option B: alias

_This option is singularly focused in terms of what it affects._

_~/.bash_profile_

1. Add an alias called ldp that points to _/path/to/project/root/vendor/bin/ldp_.

```shell
alias ldp="/path/to/project/root/vendor/bin/ldp"
```

#### Both Options Continued

2. Type `ldp` to test if it worked... you should see available commands
3. Now use `ldp` from anywhere within your project, instead of `./vendor/bin/ldp` from the root.
4. Don't worry if you have more than one project using _Live Dev Porter_ because this alias will work for multiple projects as long as they use the same version, and usually even if the versions differ.

## Quick Start Remote

1. Deploy your code to your remote server.
2. On the remote server type `./vendor/bin/ldp config -l`

## Installation

The installation script above will generate the following structure where `.` is your repository root.

    .
    └── .live_dev_porter
    │   ├── config.local.yml
    │   └── config.yml
    └── {public web root}

## Configuration Files

Refer to the file(s) for documentation about configuration options.

| Filename | Description | VCS |
|----------|----------|---|
| _.live\_dev\_porter/config.yml_ | Configuration shared across all server environments: prod, staging, dev  | yes |
| _.live\_dev\_porter/config.local.yml_ | Configuration overrides for a single environment; not version controlled. | no |

## Usage

* To see all commands use `./vendor/bin/ldp`

{{ funding|raw }}
