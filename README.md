# Whitecodel Auto Link

## Overview

This script automates the process of building and uploading Flutter APK and IPA files to Diawi.

## Video Tutorial

[![YouTube Video](https://img.youtube.com/vi/uueVxQoJqCQ/sddefault.jpg)](https://youtu.be/uueVxQoJqCQ?si=-2FqtyDamjCwEVpE)

## Prerequisites

Before using this script, make sure you have the following:

- **Flutter SDK**: Ensure that Flutter is installed on your machine. You can install it by following the instructions on the [Flutter website](https://flutter.dev/docs/get-started/install).

- **Diawi Token**: Obtain your Diawi token by visiting [https://dashboard.diawi.com/profile/api](https://dashboard.diawi.com/profile/api).

## Usage

```bash
whitecodel_auto_link <token> <buildType> <releaseType>
```

## Default Values

- If `buildType` is not provided, it defaults to `both`.
- If `releaseType` is not provided, it defaults to `debug`.

## Example

```bash
whitecodel_auto_link abcdef123456789 apk release
whitecodel_auto_link abcdef123456789 ipa release
whitecodel_auto_link abcdef123456789 both release
whitecodel_auto_link abcdef123456789 apk debug
whitecodel_auto_link abcdef123456789 ipa debug
whitecodel_auto_link abcdef123456789 both debug
```

## Author

- [Bhawani Shankar](https://www.linkedin.com/in/bhawani-shankar-mahawar-601777170/)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/whitecodel/whitecodel_auto_link/blob/main/LICENSE) file for details.
