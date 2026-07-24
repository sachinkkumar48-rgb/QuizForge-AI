// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void launchUrlCompat(String url) {
  js.context.callMethod('open', [url]);
}
