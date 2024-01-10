import 'package:whitecodel_auto_link/whitecodel_auto_link.dart';

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
