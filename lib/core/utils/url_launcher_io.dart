import 'dart:io';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.sachinkumar.quizforge/launcher');

void launchUrlCompat(String url) {
  if (Platform.isWindows) {
    Process.run('cmd', ['/c', 'start', '', url]);
  } else if (Platform.isAndroid) {
    _channel.invokeMethod('launch', {'url': url});
  }
}
