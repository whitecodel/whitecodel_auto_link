import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Please provide the token like this: whitecodel_auto_link <token>');
    print(
        'To obtain your Diawi token, visit https://dashboard.diawi.com/profile/api');

    return;
  }
  print('Starting Whitecodel Auto Link... 🚀');
  if (arguments.length == 1) {
    startProcess(arguments[0]);
  } else if (arguments.length == 2) {
    if (!['apk', 'ipa', 'both'].contains(arguments[1])) {
      print(
          'Please provide the build type like this: whitecodel_auto_link <token> <buildType>');
      print('Valid build types are: apk, ipa, both');
      return;
    }
    startProcess(arguments[0], buildType: arguments[1], releaseType: 'debug');
  } else if (arguments.length == 3) {
    if (!['apk', 'ipa', 'both'].contains(arguments[1])) {
      print(
          'Please provide the build type like this: whitecodel_auto_link <token> <buildType> <releaseType>');
      print('Valid build types are: apk, ipa, both');
      return;
    }
    if (!['debug', 'release'].contains(arguments[2])) {
      print(
          'Please provide the release type like this: whitecodel_auto_link <token> <buildType> <releaseType>');
      print('Valid release types are: debug, release');
      return;
    }
    startProcess(arguments[0],
        buildType: arguments[1], releaseType: arguments[2]);
  }
}

startProcess(diawiToken, {buildType = 'both', releaseType = 'debug'}) async {
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
      finalResult.add(
        {
          'for': 'IPA',
          'link': statusResult['link'],
          'icon': '',
        },
      );
    }
    // remove Payload
    await Directory('Payload').delete(recursive: true);
    // remove Runner.ipa
    await File('Runner.ipa').delete();
    for (var result in finalResult) {
      print('Link for ${result['for']}: ${result['link']} ${result['icon']}');
    }
    print(
        'Like the package? Please give it a 👍 here: https://pub.dev/packages/whitecodel_auto_link');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> buildApk(releaseType) async {
  // build emoji
  print('Building $releaseType APK... 🔨');
  var process =
      await Process.start('flutter', ['build', 'apk', '--$releaseType']);

  // Capture and print the output of the command
  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    print('stderr: $data');
  });

  // Wait for the process to complete
  var exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw 'Command failed with exit code $exitCode';
  }

  print('APK Build Completed Successfully');
}

Future<void> buildIPA(releaseType) async {
  // check .gitignore exists
  bool isGitIgnoreExists = await File('.gitignore').exists();
  if (isGitIgnoreExists) {
    // check Payload exists in .gitignore
    var gitIgnoreFile = await File('.gitignore').readAsString();
    if (!gitIgnoreFile.contains('Payload')) {
      // add Payload to .gitignore
      await File('.gitignore').writeAsString('$gitIgnoreFile\nPayload');
    }
    if (!gitIgnoreFile.contains('Runner.ipa')) {
      // add Runner.ipa to .gitignore
      await File('.gitignore').writeAsString('$gitIgnoreFile\nRunner.ipa');
    }
  }
  // mkdir directory Payload
  if (await Directory('Payload').exists()) {
    await Directory('Payload').delete(recursive: true);
  }
  await Directory('Payload').create();

  // build emoji
  print('Building $releaseType IPA... 🔨');
  var process =
      await Process.start('flutter', ['build', 'ios', '--$releaseType']);

  // Capture and print the output of the command
  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    print('stderr: $data');
  });

  // Wait for the process to complete
  var exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw 'Command failed with exit code $exitCode';
  }

  // copy all contents from build/ios/iphoneos/Runner.app to Payload
  var process2 = await Process.start(
      'cp', ['-r', 'build/ios/iphoneos/Runner.app', 'Payload/Runner.app']);

  // Capture and print the output of the command
  process2.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process2.stderr.transform(utf8.decoder).listen((data) {
    print('stderr: $data');
  });

  var exitCode2 = await process2.exitCode;

  if (exitCode2 != 0) {
    throw 'Command failed with exit code $exitCode2';
  }

  // zip Payload
  var process3 = await Process.start('zip', ['-vr', 'Runner.ipa', 'Payload']);

  // Capture and print the output of the command
  process3.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process3.stderr.transform(utf8.decoder).listen((data) {
    print('stderr: $data');
  });

  var exitCode3 = await process3.exitCode;

  if (exitCode3 != 0) {
    throw 'Command failed with exit code $exitCode3';
  }

  print('IPA Build Completed Successfully');
}

Future<Map<String, dynamic>> uploadToDiawi(diawiToken, path, buildType) async {
  print('Your Diawi Token: $diawiToken');
  print('Uploading ${buildType.toUpperCase()} to Diawi... 🚀');
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
  print('Checking Diawi Status... 🕵️‍♂️');
  var diawiStatusUrl =
      'https://upload.diawi.com/status?token=$diawiToken&job=$jobId';

  var response = await http.get(Uri.parse(diawiStatusUrl));

  return json.decode(response.body);
}
