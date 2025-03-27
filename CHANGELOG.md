# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
