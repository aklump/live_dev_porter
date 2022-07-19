# Live Dev Porter

![live_dev_porter](images/live-dev-porter.jpg)

## Summary

Simplifies the management and transfer of assets between website environments.

**Visit <https://aklump.github.io/live_dev_porter> for full documentation.**

## Quick Start

- Require in your project using `composer require aklump/live-dev-porter`
- Ensure execute permissions: `chmod u+x ./vendor/bin/ldp`
- (To migrate from Loft Deploy use, `./vendor/bin/ldp config-migrate ./.loft_deploy`, otherwise...)
- Initialize your project using `./vendor/bin/ldp init`
- Open _.live_dev_porter/config.yml_ and modify as needed.
- **Ensure _config.local.yml_ is ignored by your SCM!**
- Open _.live_dev_porter/config.local.yml_ and define the correct `local` and `remote` environment IDs as defined in _config.yml_.

### Optional Shorthand `ldp` instead of `./vendor/bin/ldp`

1. Add _./vendor/bin_ to your `$PATH` variable (probably in _~/.bash_profile_).
2. Type `ldp` to test if it worked... you should see available commands
3. Now use `ldp` from anywhere within your project, instead of `./vendor/bin/ldp` from the root.
4. Don't worry if you have more than one project using _Live Dev Porter_ because this alias will work for multiple projects as long as they use the same version, and usually even if the versions differ.

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
| _.live_dev_porter/config.yml_ | Configuration shared across all server environments: prod, staging, dev  | yes |
| _.live_dev_porter/config.local.yml_ | Configuration overrides for a single environment; not version controlled. | no |

## Usage

* To see all commands use `./vendor/bin/ldp`

## Contributing

If you find this project useful... please consider [making a donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Gratitude%20for%20aklump%2Flive_dev_porter).
