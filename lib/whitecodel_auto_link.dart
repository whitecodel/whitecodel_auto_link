import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:chalkdart/chalk.dart';

var error = chalk.bold.red;
var info = chalk.bold.blue;

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print(error(
        'Error: Please provide the token like this: ${chalk.yellow('whitecodel_auto_link <token>')}'));
    print(info(
        'Info: To obtain your Diawi token, visit https://dashboard.diawi.com/profile/api'));
    return;
  }

  print(info('Info: Starting Whitecodel Auto Link... 🚀'));

  if (arguments.length == 1) {
    startProcess(arguments[0]);
  } else if (arguments.length == 2) {
    if (!['apk', 'ipa', 'both'].contains(arguments[1])) {
      print(error(
          'Error: Invalid build type. Valid build types are: ${chalk.yellow('apk, ipa, both')}'));
      return;
    }
    startProcess(arguments[0], buildType: arguments[1], releaseType: 'debug');
  } else if (arguments.length == 3) {
    if (!['apk', 'ipa', 'both'].contains(arguments[1])) {
      print(error(
          'Error: Invalid build type. Valid build types are: ${chalk.yellow('apk, ipa, both')}'));
      return;
    }
    if (!['debug', 'release'].contains(arguments[2])) {
      print(error(
          'Error: Invalid release type. Valid release types are: ${chalk.yellow('debug, release')}'));
      return;
    }
    startProcess(arguments[0],
        buildType: arguments[1], releaseType: arguments[2]);
  }
}

void startProcess(diawiToken,
    {buildType = 'both', releaseType = 'debug'}) async {
  try {
    var finalResult = [];

    if (buildType == 'apk' || buildType == 'both') {
      await buildApk(releaseType);
      var uploadResult = await uploadToDiawi(diawiToken,
          'build/app/outputs/apk/release/app-$releaseType.apk', 'APK');
      var jobId = uploadResult['job'];
      var statusResult = await checkDiawiStatus(jobId, diawiToken);

      while (statusResult['status'] != 2000) {
        await Future.delayed(Duration(seconds: 5));
        statusResult = await checkDiawiStatus(jobId, diawiToken);
      }

      finalResult.add({
        'for': 'APK',
        'link': statusResult['link'],
        'icon': '🤖',
      });
    }

    if (buildType == 'ipa' || buildType == 'both') {
      await buildIPA(releaseType);
      var uploadResult = await uploadToDiawi(diawiToken, 'Runner.ipa', 'IPA');
      var jobId = uploadResult['job'];
      var statusResult = await checkDiawiStatus(jobId, diawiToken);

      while (statusResult['status'] != 2000) {
        await Future.delayed(Duration(seconds: 5));
        statusResult = await checkDiawiStatus(jobId, diawiToken);
      }

      finalResult.add({
        'for': 'IPA',
        'link': statusResult['link'],
        'icon': '',
      });
    }

    await Directory('Payload').delete(recursive: true);
    await File('Runner.ipa').delete();

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

Future<Map<String, dynamic>> uploadToDiawi(diawiToken, path, buildType) async {
  print(info('Info: Your Diawi Token: ${chalk.yellow(diawiToken)}'));
  print(info('Info: Uploading ${buildType.toUpperCase()} to Diawi... 🚀'));
  var diawiUploadUrl = 'https://upload.diawi.com/';

  var request = http.MultipartRequest('POST', Uri.parse(diawiUploadUrl))
    ..fields['token'] = diawiToken
    ..fields['callback_emails'] = 'bhawanishankar1308@gmail.com'
    ..files.add(await http.MultipartFile.fromPath('file', path));

  var response = await request.send();

  var responseBody = await response.stream.toBytes();

  var responseString = String.fromCharCodes(responseBody);

  return json.decode(responseString);
}

Future<Map<String, dynamic>> checkDiawiStatus(String jobId, diawiToken) async {
  print(info('Info: Checking Diawi Status... 🕵️‍♂️'));
  var diawiStatusUrl =
      'https://upload.diawi.com/status?token=$diawiToken&job=$jobId';

  var response = await http.get(Uri.parse(diawiStatusUrl));

  return json.decode(response.body);
}
