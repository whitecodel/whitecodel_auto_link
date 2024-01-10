import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  startProcess();
}

startProcess() async {
  try {
    // Step 1: Build APK
    await buildApk();

    // Step 2: Upload APK to Diawi
    var diawiUploadResponse = await uploadToDiawi();

    print('Diawi Upload Response: $diawiUploadResponse');

    // // Extracting job ID from the Diawi Upload Response
    var jobId = diawiUploadResponse['job'];

    // // Step 3: Check Diawi Upload Status
    var diawiStatusResponse;
    do {
      await Future.delayed(Duration(seconds: 2));
      diawiStatusResponse = await checkDiawiStatus(jobId);
      print('Diawi Status Response: $diawiStatusResponse');
    } while (diawiStatusResponse['status'] != 2000);
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> buildApk() async {
  // build emoji
  print('Building APK... 🔨');
  var process = await Process.start('flutter', ['build', 'apk', '--release']);

  // Capture and print the output of the command
  process.stdout.transform(utf8.decoder).listen((data) {
    print('stdout: $data');
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

Future<Map<String, dynamic>> uploadToDiawi() async {
  print('Uploading APK to Diawi... 🚀');
  var diawiUploadUrl = 'https://upload.diawi.com/';

  var request = http.MultipartRequest('POST', Uri.parse(diawiUploadUrl))
    ..fields['token'] = '6rTDnqLWVfRM5Izlx74Rql58Qzd3wdmXg1xjGTNtji'
    ..fields['callback_emails'] = 'bhawanishankar1308@gmail.com'
    ..files.add(await http.MultipartFile.fromPath(
        'file', 'build/app/outputs/apk/release/app-release.apk'));

  var response = await request.send();

  var responseBody = await response.stream.toBytes();

  var responseString = String.fromCharCodes(responseBody);

  return json.decode(responseString);
}

Future<Map<String, dynamic>> checkDiawiStatus(String jobId) async {
  print('Checking Diawi Status... 🕵️‍♂️');
  var diawiStatusUrl =
      'https://upload.diawi.com/status?token=6rTDnqLWVfRM5Izlx74Rql58Qzd3wdmXg1xjGTNtji&job=$jobId';

  var response = await http.get(Uri.parse(diawiStatusUrl));

  return json.decode(response.body);
}
