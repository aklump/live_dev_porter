# Live Dev Porter

![live_dev_porter](docs/images/live-dev-porter.jpg)

## Summary

Simplifies the management and transfer of assets between website environments.

**Visit <https://aklump.github.io/live_dev_porter> for full documentation.**

## Quick Start

- Install in your repository root using `cloudy pm-install aklump/live_dev_porter`
- Open _.live_dev_porter/config.yml_ and modify as needed.
- Open _.live_dev_porter/config.local.yml_ and ...; be sure to ignore this file in SCM.
- Try it out with `./bin/live_dev_porter SOME_COMMAND`

## Requirements

You must have [Cloudy](https://github.com/aklump/cloudy) installed on your system to install this package.

## Installation

The installation script above will generate the following structure where `.` is your repository root.

    .
    ├── .live_dev_porter
    │   ├── backups
    │   │   └── dev
    │   │       └── db
    │   │           ├── data_exclusions.txt
    │   │           └── table_exclusions.txt
    │   ├── config.local.yml
    │   ├── config.yml
    │   └── fetch
    │       └── live
    │           ├── db
    │           └── files
    │               └── *.ignore.txt
    ├── bin
    │   ├── live_dev_porter -> ../opt/live_dev_porter/live_dev_porter.sh
    ├── opt
    │   ├── cloudy
    │   └── aklump
    │       └── live_dev_porter
    └── {public web root}

    
### To Update

- Update to the latest version from your repo root: `cloudy pm-update aklump/live_dev_porter`

## Configuration Files

Refer to the file(s) for documentation about configuration options.

| Filename | Description | VCS |
|----------|----------|---|
| _.live_dev_porter/config.yml_ | Configuration shared across all server environments: prod, staging, dev  | yes |
| _.live_dev_porter/config.local.yml_ | Configuration overrides for a single environment; not version controlled. | no |

## Usage

* To see all commands use `./bin/live_dev_porter`

## Contributing

If you find this project useful... please consider [making a donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Gratitude%20for%20aklump%2Flive_dev_porter).
