import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:version/version.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

void main(List<String> args) {
  final pubspecFile = File('pubspec.yaml');
  final pubspecContent = pubspecFile.readAsStringSync();

  // Parse the pubspec.yaml content
  final pubspec = Pubspec.parse(pubspecContent);

  // Access the version
  final version = pubspec.version;
  print('Current version: ${version.toString()}');
  final package = args[0];
  PubDevApi.getLatestVersionFromPackage(package).then((value) {
    if (value == null) {
      print('Failed to get the latest version of $package');
      return;
    }
    final currentVersion = Version.parse(args[1]);
    final latestVersion = Version.parse(value);
    if (latestVersion > currentVersion) {
      print('A new version of $package is available: $latestVersion');
    } else {
      print('The current version of $package is up to date');
    }
  });
}

class PubDevApi {
  static Future<String?> getLatestVersionFromPackage(String package) async {
    // check if internet is available
    try {
      final result = await InternetAddress.lookup('pub.dev');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Info: Internet is available');
      }
    } on SocketException catch (_) {
      // kill the process if no internet is available
      print('Error: No internet connection');
      exit(1);
    }
    final languageCode = Platform.localeName.split('_')[0];
    final pubSite = languageCode == 'zh'
        ? 'https://pub.flutter-io.cn/api/packages/$package'
        : 'https://pub.dev/api/packages/$package';
    var uri = Uri.parse(pubSite);
    try {
      final value = await Dio().getUri(uri);
      print(value.data.runtimeType);
      final version = value.data['latest']['version'] as String?;
      return version;
    } catch (e) {
      return null;
    }
  }
}
