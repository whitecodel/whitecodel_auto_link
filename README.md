# Whitecodel Auto Link

## Overview

This script automates the process of building and uploading Flutter APK and IPA files to WhiteCodel App Share.

Support for IPA building and APK uploading simultaneously speed up the process 🚀

## Video Tutorial

[![YouTube Video](https://img.youtube.com/vi/uueVxQoJqCQ/sddefault.jpg)](https://www.youtube.com/watch?v=ZCZ2ic0ePlQ)

## Prerequisites

Before using this script, make sure you have the following:

- **Flutter SDK**: Ensure that Flutter is installed on your machine. You can install it by following the instructions on the [Flutter website](https://flutter.dev/docs/get-started/install).

- **WhiteCodel App Share Token**: Obtain your WhiteCodel App Share token by visiting [https://tools.whitecodel.com/account](https://tools.whitecodel.com/account).

## Installation

```bash
dart pub global activate whitecodel_auto_link
```

## Usage

```bash
whitecodel_auto_link login
```

```bash
whitecodel_auto_link logout
```

```bash
whitecodel_auto_link
```

```bash
whitecodel_auto_link only-upload
```

```bash
whitecodel_auto_link u
```

This command will prompt you to enter the file path of the APK or IPA file you want to upload. The `u` flag is a shorthand for `only-upload`.

## Changelog

See the [CHANGELOG](CHANGELOG.md) file for details.

## Author

- [Bhawani Shankar](https://www.linkedin.com/in/bhawani-shankar-mahawar-601777170/)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/whitecodel/whitecodel_auto_link/blob/main/LICENSE) file for details.
