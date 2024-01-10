import 'package:whitecodel_auto_link/whitecodel_auto_link.dart'
    as whitecodel_auto_link;

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Please provide the token like this: whitecodel_auto_link <token>');
    print(
        'To obtain your Diawi token, visit https://dashboard.diawi.com/profile/api');

    return;
  }
  print('Starting Whitecodel Auto Link... 🚀');
  whitecodel_auto_link.startProcess(arguments[0]);
}
