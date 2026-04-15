# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.8](https://github.com/Flytedesk/debounced/compare/v1.0.7...v1.0.8) (2026-04-15)


### Bug Fixes

* **deps:** bump dependabot/fetch-metadata from 2 to 3 ([#18](https://github.com/Flytedesk/debounced/issues/18)) ([3bd38de](https://github.com/Flytedesk/debounced/commit/3bd38deb307558e491619ce544b30e3c822df38b))
* **deps:** bump the bundler-non-major group with 3 updates ([#17](https://github.com/Flytedesk/debounced/issues/17)) ([bbc6078](https://github.com/Flytedesk/debounced/commit/bbc60783c600b6d3d4a65628e08f8f35c5b3cec2))

## [1.0.7](https://github.com/Flytedesk/debounced/compare/v1.0.6...v1.0.7) (2026-04-15)


### Bug Fixes

* **deps:** bump dependabot/fetch-metadata from 2 to 3 ([#18](https://github.com/Flytedesk/debounced/issues/18)) ([3bd38de](https://github.com/Flytedesk/debounced/commit/3bd38deb307558e491619ce544b30e3c822df38b))
* **deps:** bump the bundler-non-major group with 3 updates ([#17](https://github.com/Flytedesk/debounced/issues/17)) ([bbc6078](https://github.com/Flytedesk/debounced/commit/bbc60783c600b6d3d4a65628e08f8f35c5b3cec2))

## [1.0.0] - 2025-03-21

- Initial release
- Core functionality extracted from supply-side-platform
- Ruby wrapper for Node.js event debouncing service
- Configuration options for socket descriptor

## [1.0.1] - 2025-03-21

- Removed dependency on 'json/add/core' that seemed to interfere with Rails JSON serialization

## [1.0.2] - 2025-03-26

- Fixed bug where Ruby (proxy) would allow messages to be sent to Javascript (server), even if the Ruby (proxy) was not listening for messages from Javascript (server)

## [1.0.3] - 2025-03-26

- Avoid using a trace log level, which is not supported by the default Rails loggers.

## [1.0.4] - 2025-04-11

- Avoid using a debug log level for trace messages in a loop.
- Lazy initialization of SemanticLogger, only if Gem configuration doesn't get another logger from host application.

## [1.0.5] - 2025-11-11

- Update dependencies.
