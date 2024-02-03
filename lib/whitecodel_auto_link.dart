import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:chalkdart/chalk.dart';
import 'package:interact/interact.dart';

var error = chalk.bold.red;
var info = chalk.bold.blue;

void main(List<String> arguments) {
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

    if (buildType == 'apk' || buildType == 'both') {
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

    if (buildType == 'ipa' || buildType == 'both') {
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

    if (await Directory('Payload').exists()) {
      await Directory('Payload').delete(recursive: true);
    }
    if (await File('Runner.ipa').exists()) {
      await File('Runner.ipa').delete();
    }

    print('\n');

    for (var result in finalResult) {
      print(info(
          'Info: Link for ${result['for']}: ${chalk.green.underline(result['link'])} ${chalk.green(result['icon'])}'));
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
  print(info('Info: Building $releaseType APK... 🔨'));
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

  print(info('Info: APK Build Completed Successfully'));
}

Future<void> buildIPA(releaseType) async {
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

  print(info('Info: IPA Build Completed Successfully'));
}

Future<dynamic> uploadToWhiteCodelAppShare(token, path, buildType) async {
  print(info('Info: Your WhiteCodel App Share Token: ${chalk.yellow(token)}'));
  print(info(
      'Info: Uploading ${buildType.toUpperCase()} to WhiteCodel App Share... 🚀'));
  var diawiUploadUrl = 'https://tools.whitecodel.com/app-share/uploadFile';

  var request = http.MultipartRequest('POST', Uri.parse(diawiUploadUrl))
    ..files
        .add(await http.MultipartFile.fromPath('file', path))
    ..headers['token'] = token;

  var response = await request.send();

  // check status code
  if (response.statusCode == 401) {
    throw error('Invalid Token');
  }

  // if (response.statusCode > 299) {
  //   throw error('Try again later');
  // }

  var responseBody = await response.stream.toBytes();

  var responseString = String.fromCharCodes(responseBody);

  print(info('Info: ${responseString}'));

  return json.decode(responseString);
}
