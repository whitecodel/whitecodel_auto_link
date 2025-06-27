import 'package:whitecodel_auto_link/whitecodel_auto_link.dart';
import 'package:chalkdart/chalk.dart';
import 'dart:io';
import 'package:interact/interact.dart';

var error = chalk.bold.red;
var info = chalk.bold.blue;

void main(List<String> arguments) async {
  // Clear console
  print('\x1B[2J\x1B[0;0H');

  // Check for update
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

  // Read token file
  var file = File(path);
  if (file.existsSync()) {
    token = file.readAsStringSync().trim();
  }

  String argumentsString = arguments.join(' ');

  if (token == null && argumentsString != 'login') {
    print(error(
        'Error: Please provide the token using: ${chalk.yellow('whitecodel_auto_link login')}'));
    print(info(
        'Info: To obtain your WhiteCodel App Share token, visit https://tools.whitecodel.com/account'));
    return;
  }

  switch (argumentsString) {
    case 'login':
      stdout.write('Enter your token: ');
      var enteredValue = stdin.readLineSync()?.trim();
      if (enteredValue != null && enteredValue.isNotEmpty) {
        file.createSync(recursive: true);
        file.writeAsStringSync(enteredValue);
        print(info('Info: Token has been updated successfully'));
      } else {
        print(error('Error: Token cannot be empty'));
      }
      return;

    case 'logout':
      if (file.existsSync()) {
        file.deleteSync();
      }
      print(info('Info: Token has been removed successfully'));
      return;

    case 'only-upload':
    case 'u':
      stdout.write('Enter the file path: ');
      var filePath = await readLine();
      if (filePath == null || filePath.trim().isEmpty) {
        print(error('Error: File path cannot be empty'));
        return;
      }

      // Ensure proper file path formatting
      filePath = formatPath(filePath);

      var fileToUpload = File(filePath);
      if (!fileToUpload.existsSync()) {
        print(error(
            'Error: File does not exist at the provided path: $filePath'));
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

  // Select build type
  List<String> buildTypeOptions = ['apk', 'ipa', 'both'];
  var selectedBuildTypeIndex =
      Select(prompt: 'Select the build type', options: buildTypeOptions)
          .interact();
  buildType = buildTypeOptions[selectedBuildTypeIndex];

  // Select release type
  List<String> releaseTypeOptions = ['debug', 'release'];
  var selectedReleaseTypeIndex =
      Select(prompt: 'Select the release type', options: releaseTypeOptions)
          .interact();
  releaseType = releaseTypeOptions[selectedReleaseTypeIndex];

  startProcess(token, releaseType: releaseType, buildType: buildType);
}

Future<String?> readLine() async {
  stdout.write('> ');
  return stdin.readLineSync()?.trim();
}

String formatPath(String path) {
  // Remove surrounding quotes if present
  if ((path.startsWith("'") && path.endsWith("'")) ||
      (path.startsWith('"') && path.endsWith('"'))) {
    path = path.substring(1, path.length - 1);
  }
  // Convert to absolute path if needed
  var file = File(path);
  if (!file.isAbsolute) {
    path = file.absolute.path;
  }
  return path.replaceAll('\\ ', ' '); // Fixes macOS issue with backslashes
}
