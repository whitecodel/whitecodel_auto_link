# Changelog

## [1.1.19] - 2025-02-20

### Added

- Added `upload-from-url` and shorthand `uf` commands to upload APK or IPA files directly from a remote URL.

## [1.1.18] - 2025-02-20

### Added

- Added shorthand `u` flag that works the same as `only-upload` command for quicker file uploads.

## [1.1.17] - 2025-02-20

### Fixed

- Fixed file path handling issue on macOS by correctly formatting paths with spaces.
- Ensured proper token validation to prevent empty token errors.
- Improved absolute path conversion for better cross-platform support.

## [1.1.16] - 2025-02-05

### Fixed

- Asking update again and again issue fixed.
- Improved validation for file existence and supported file types in the `only-upload` command.

## [1.1.15] - 2025-02-05

### Added

- Added `only-upload` command to upload APK or IPA files directly by providing the file path.

### Fixed

- Improved validation for file existence and supported file types in the `only-upload` command.
