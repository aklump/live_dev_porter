<!--
id: changelog
tags: ''
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.138] - 2023-09-26

### Changed

- All PHP Processors must use the namespace `AKlump\LiveDevPorter\Processors\`

## [0.0.120] - 2023-06-01

### Added

- You can now set the `local` or `remote` env from CLI using `ldp config local <ENV>` or `ldp config remote <ENV>`, without opening an editor.

## [0.0.109] - 2023-02-12

### Changed

- How the process command gets it's environment variables. Add --config and --verbose to the process command.

### Removed

- The --env option from the process command. To set the variables you must now use "process --config"

## [0.0.105] - 2022-12-08

### Added

- `\AKlump\LiveDevPorter\Processors\PhpTrait` for processing PHP files secrets.

## [0.0.101] - 2022-11-08

### Added

- `ldp push` operation
- Added `preprocessors` to workflows for database push and pull.
- configuration option `backup_remote_db_on_push`

### Changed

- `compress_pull_dumpfiles` has been renamed to `compress_dumpfiles`. If you have set this value you must update the variable name in your configuration. See _live_dev_porter.core.yml_ for default.
