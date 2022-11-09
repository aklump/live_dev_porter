# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.101] - 2022-11-08

### Added

- `ldp push` operation
- Added `preprocessors` to workflows for database push and pull.
- configuration option `backup_remote_db_on_push`

### Changed

- `compress_pull_dumpfiles` has been renamed to `compress_dumpfiles`. If you have set this value you must update the variable name in your configuration. See _live_dev_porter.core.yml_ for default.
