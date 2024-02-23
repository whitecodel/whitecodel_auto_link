import 'package:whitecodel_auto_link/whitecodel_auto_link.dart';
import 'package:chalkdart/chalk.dart';
import 'dart:io';
import 'package:interact/interact.dart';

var error = chalk.bold.red;
var info = chalk.bold.blue;

void main(List<String> arguments) {
  print('\x1B[2J\x1B[0;0H');
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
