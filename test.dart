import 'dart:async';
import 'dart:io';

void main(List<String> args) {
  int ticks = 0;
  var timer = Timer.periodic(Duration(seconds: 1), (timer) {
    stdout.write('\rBuilding APK: ${ticks++}s');
  });

  Future.delayed(Duration(seconds: 5), () {
    timer.cancel();
    // replace text with APK Build completed at 5s
    print('\rDone APK: 5s');
  });
}
