import 'dart:async';

import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:chalkdart/chalk.dart';
import 'package:interact/interact.dart';
import 'package:dio/dio.dart' as dio;
import 'package:version/version.dart';

var error = chalk.bold.red;
var info = chalk.bold.blue;
var moreHighlight = chalk.bold.green;

void main(List<String> arguments) async {
  // clear console
  print('\x1B[2J\x1B[0;0H');
  // check for update
  await checkForUpdate();
  String? token;

  String? username =
      Platform.environment['USER'] ?? Platform.environment['USERNAME'];

  String? macPath = '/Users/$username/.whitecodel-app-share-token.txt';
  String? linuxPath = '/home/$username/.whitecodel-app-share-token.txt';
  String? windowsPath = 'C:\\Users\\$username\\.whitecodel-app-share-token.txt';

  String path = Platform.isMacOS
      ? macPath
      : Platform.isLinux
          ? linuxPath
          : windowsPath;

  // read file path
  var file = File(path);
  if (file.existsSync()) {
    token = file.readAsStringSync();
  }

  String argumentsString = arguments.join(' ');

  if (token == null && argumentsString != 'login') {
    print(error(
        'Error: Please provide the token use this: ${chalk.yellow('whitecodel_auto_link login')}'));
    print(info(
        'Info: To obtain your WhiteCodel App Share token, visit https://tools.whitecodel.com/account'));
    return;
  }

  switch (argumentsString) {
    case 'login':
      // Ask the user for input
      stdout.write('Enter a value: ');
      // Read the entered value
      var enteredValue = stdin.readLineSync();
      token = enteredValue;
      file.createSync();
      // write to file path
      file.writeAsStringSync(token!);
      print(info('Info: Token has been updated successfully'));
      return;
    case 'logout':
      token = null;
      // delete file path
      file.deleteSync();
      print(info('Info: Token has been removed successfully'));
      return;
    case 'only-upload':
      stdout.write('Enter the file path: ');
      var filePath = stdin.readLineSync();
      if (filePath == null || filePath.isEmpty) {
        print(error('Error: File path cannot be empty'));
        return;
      }
      var fileToUpload = File(filePath);
      if (!fileToUpload.existsSync()) {
        print(error('Error: File does not exist'));
        return;
      }
      var buildType = filePath.endsWith('.apk')
          ? 'APK'
          : filePath.endsWith('.ipa')
              ? 'IPA'
              : null;
      if (buildType == null) {
        print(error(
            'Error: Unsupported file type. Please provide an APK or IPA file.'));
        return;
      }
      var uploadResult =
          await uploadToWhiteCodelAppShare(token, filePath, buildType);
      var appMetaDoc = uploadResult['appMetaDoc'];
      var appUrl = appMetaDoc['appUrl'];
      print(info(
          'Info: Link for $buildType: ${chalk.green.underline(appUrl)} ${buildType == 'APK' ? '🤖' : ''}'));
      return;
  }

  String buildType = '';
  String releaseType = '';

  // select build type
  List<String> buildTypeOptions = ['apk', 'ipa', 'both'];
  var selectedBuildTypeIndex = Select(
    prompt: 'Select the build type',
    options: buildTypeOptions,
  ).interact();
  buildType = buildTypeOptions[selectedBuildTypeIndex];

  // select release type
  List<String> releaseTypeOptions = ['debug', 'release'];
  var selectedReleaseTypeIndex = Select(
    prompt: 'Select the release type',
    options: releaseTypeOptions,
  ).interact();
  releaseType = releaseTypeOptions[selectedReleaseTypeIndex];

  startProcess(token, releaseType: releaseType, buildType: buildType);
}

void startProcess(
  token, {
  releaseType = 'debug',
  buildType = 'both',
}) async {
  try {
    var finalResult = [];

    if (buildType == 'apk') {
      await buildApk(releaseType);
      var uploadResult = await uploadToWhiteCodelAppShare(
          token, 'build/app/outputs/flutter-apk/app-$releaseType.apk', 'APK');
      var appMetaDoc = uploadResult['appMetaDoc'];
      var appUrl = appMetaDoc['appUrl'];

      finalResult.add({
        'for': 'APK',
        'link': appUrl,
        'icon': '🤖',
      });
    }

    if (buildType == 'ipa') {
      await buildIPA(releaseType);
      var uploadResult =
          await uploadToWhiteCodelAppShare(token, 'Runner.ipa', 'IPA');
      var appMetaDoc = uploadResult['appMetaDoc'];
      var appUrl = appMetaDoc['appUrl'];

      finalResult.add({
        'for': 'IPA',
        'link': appUrl,
        'icon': '',
      });
    }

    if (buildType == 'both') {
      await buildApk(releaseType);
      print(moreHighlight(
          'Info: Uploading APK and Building IPA simultaneously... 🚀'));
      List futureResults = await Future.wait([
        uploadToWhiteCodelAppShare(
            token, 'build/app/outputs/flutter-apk/app-$releaseType.apk', 'APK'),
        buildIPA(releaseType),
      ]);
      var uploadResult = futureResults[0];
      var appMetaDoc = uploadResult['appMetaDoc'];
      var appUrl = appMetaDoc['appUrl'];

      finalResult.add({
        'for': 'APK',
        'link': appUrl,
        'icon': '🤖',
      });

      var uploadResult2 =
          await uploadToWhiteCodelAppShare(token, 'Runner.ipa', 'IPA');
      var appMetaDoc2 = uploadResult2['appMetaDoc'];
      var appUrl2 = appMetaDoc2['appUrl'];

      finalResult.add({
        'for': 'IPA',
        'link': appUrl2,
        'icon': '',
      });
    }

    if (await Directory('Payload').exists()) {
      await Directory('Payload').delete(recursive: true);
    }
    if (await File('Runner.ipa').exists()) {
      await File('Runner.ipa').delete();
    }

    print('\n');

    for (var result in finalResult) {
      print(info(
          'Info: Link for ${result['for']}: ${chalk.green.underline(result['link'])} ${result['icon']}'));
    }

    print('\n\n');

    print(info(
        'Info: Like the package? Please give it a 👍 here: ${chalk.green.underline('https://pub.dev/packages/whitecodel_auto_link')}'));
  } catch (e) {
    print(error('Error: $e'));
    exit(1);
  }
}

Future<void> buildApk(releaseType) async {
  double ticks = 0.0;
  print(info('Info: Building $releaseType APK... 🔨'));
  var timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
    ticks += 0.1;
    stdout.write(
        '\rBuilding APK... \x1B[90m(${ticks.toStringAsFixed(1)}s)\x1B[0m\r');
  });
  var process =
      await Process.start('flutter', ['build', 'apk', '--$releaseType']);

  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    print(error('Error: $data'));
  });

  var exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw error('Error: Command failed with exit code $exitCode');
  }

  timer.cancel();
  stdout.write(
      '\rBuilding APK Done \x1B[90m(${ticks.toStringAsFixed(1)}s)\x1B[0m\n');

  print(info('Info: APK Build Completed Successfully'));
}

Future<void> buildIPA(releaseType) async {
  double ticks = 0.0;
  bool isGitIgnoreExists = await File('.gitignore').exists();

  if (isGitIgnoreExists) {
    var gitIgnoreFile = await File('.gitignore').readAsString();

    if (!gitIgnoreFile.contains('Payload')) {
      await File('.gitignore').writeAsString('$gitIgnoreFile\nPayload');
    }

    if (!gitIgnoreFile.contains('Runner.ipa')) {
      await File('.gitignore').writeAsString('$gitIgnoreFile\nRunner.ipa');
    }
  }

  if (await Directory('Payload').exists()) {
    await Directory('Payload').delete(recursive: true);
  }
  await Directory('Payload').create();

  print(info('Info: Building $releaseType IPA... 🔨'));

  var timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
    ticks += 0.1;
    stdout.write(
        '\rBuilding IPA... \x1B[90m(${ticks.toStringAsFixed(1)}s)\x1B[0m\r');
  });

  var process =
      await Process.start('flutter', ['build', 'ios', '--$releaseType']);

  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    print(error('Error: $data'));
  });

  var exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw error('Error: Command failed with exit code $exitCode');
  }

  var process2 = await Process.start(
      'cp', ['-r', 'build/ios/iphoneos/Runner.app', 'Payload/Runner.app']);

  process2.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process2.stderr.transform(utf8.decoder).listen((data) {
    print(error('Error: $data'));
  });

  var exitCode2 = await process2.exitCode;

  if (exitCode2 != 0) {
    throw error('Error: Command failed with exit code $exitCode2');
  }

  var process3 = await Process.start('zip', ['-vr', 'Runner.ipa', 'Payload']);

  process3.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process3.stderr.transform(utf8.decoder).listen((data) {
    print(error('Error: $data'));
  });

  var exitCode3 = await process3.exitCode;

  if (exitCode3 != 0) {
    throw error('Error: Command failed with exit code $exitCode3');
  }

  timer.cancel();
  stdout.write(
      '\rBuilding IPA Done \x1B[90m(${ticks.toStringAsFixed(1)}s)\x1B[0m\n');

  print(info('Info: IPA Build Completed Successfully'));
}

Future<dynamic> uploadToWhiteCodelAppShare(token, path, buildType) async {
  print(info('Info: Your WhiteCodel App Share Token: ${chalk.yellow(token)}'));
  print(info(
      'Info: Uploading ${buildType.toUpperCase()} to WhiteCodel App Share... 🚀'));

  var diawiUploadUrl = 'https://tools.whitecodel.com/app-share/uploadFile';

  Dio dioObject = Dio();

  FormData formData = FormData();
  formData.fields.add(MapEntry('token', token));
  formData.files.add(MapEntry('file', await dio.MultipartFile.fromFile(path)));

  var response = await dioObject.post(
    diawiUploadUrl,
    options: Options(
      headers: {
        'Content-Type': 'multipart/form-data',
        'token': token,
      },
    ),
    data: formData,
    onSendProgress: (int sent, int total) {
      num newTotal = total / 1024;
      num newSent = sent / 1024;
      String sizeUnit;
      num size;
      if (newTotal <= 1024) {
        size = newTotal.toDouble();
        sizeUnit = 'KB';
      } else {
        size = newTotal / 1024.0; // Convert to MB
        newSent = newSent / 1024.0; // Convert to MB
        sizeUnit = 'MB';
      }
      double percentage = (sent / total) * 100;
      size = double.parse(size.toStringAsFixed(2));
      newSent = double.parse(newSent.toStringAsFixed(2));
      stdout.write(
          '\rUploading ${buildType.toUpperCase()}... \x1B[90mSent: $newSent $sizeUnit / $size $sizeUnit (${percentage.toStringAsFixed(1)}%)\x1B[0m\r');
      // spacer next line
    },
  );

  stdout
      .write('\rUploading ${buildType.toUpperCase()}... \x1B[90m Done\x1B[0m');

  print('\n');

  if (buildType.toUpperCase() == 'APK') {
    print(info(
        'Info: Link for ${buildType.toUpperCase()}: ${chalk.green.underline(response.data['appMetaDoc']['appUrl'])} ${buildType.toUpperCase() == 'APK' ? '🤖' : ''}'));
  }

  if (response.statusCode != 200) {
    throw error('Error: Failed to upload $buildType to WhiteCodel App Share');
  }

  var responseBody = response.data;

  return responseBody;
}

checkInternet() async {
  try {
    final result = await InternetAddress.lookup('pub.dev');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print(info('Info: Internet is available'));
    }
    return true;
  } on SocketException catch (_) {
    print(chalk.yellow('Warning: No internet connection'));
    return false;
  }
}

getLatestVersionFromPackage(String package) async {
  final languageCode = Platform.localeName.split('_')[0];
  final pubSite = languageCode == 'zh'
      ? 'https://pub.flutter-io.cn/api/packages/$package'
      : 'https://pub.dev/api/packages/$package';
  var uri = Uri.parse(pubSite);
  try {
    final value = await Dio().getUri(uri);
    final version = value.data['latest']['version'] as String?;
    return version;
  } catch (e) {
    return null;
  }
}

getCurrentVersion() async {
  // final pubspecFile = File('pubspec.yaml');
  // final pubspecContent = pubspecFile.readAsStringSync();
  // final pubspec = Pubspec.parse(pubspecContent);
  // final version = pubspec.version;
  // return version.toString();
  return '1.1.15';
}

checkForUpdate() async {
  print(info('Info: Checking for update'));
  bool isInternet = await checkInternet();
  if (!isInternet) {
    print(chalk.yellow('Warning: Update check failed'));
    return;
  }
  var versionInPubDev =
      await getLatestVersionFromPackage('whitecodel_auto_link');
  var versionInstalled = await getCurrentVersion();

  if (versionInstalled == null) {
    exit(2);
  }

  final v1 = Version.parse(versionInPubDev!);
  final v2 = Version.parse(versionInstalled);
  final needsUpdate = v1.compareTo(v2);
  // needs update.

  if (needsUpdate == 1) {
    print(info('Info: Update available for whitecodel_auto_link'));
    print(info(
        'Info: Run ${chalk.green('flutter pub global activate whitecodel_auto_link')} to update'));

    // ask for update
    var shouldUpdate = Confirm(
      prompt: 'Do you want to update whitecodel_auto_link?',
    ).interact();

    if (shouldUpdate) {
      var process = await Process.start(
          'flutter', ['pub', 'global', 'activate', 'whitecodel_auto_link']);
      process.stdout.transform(utf8.decoder).listen((data) {
        print(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        print(error('Error: $data'));
      });

      var exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw error('Error: Command failed with exit code $exitCode');
      }
    }
  } else {
    print(info('Info: whitecodel_auto_link is up to date'));
  }
}
