import 'package:whitecodel_auto_link/whitecodel_auto_link.dart';
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
