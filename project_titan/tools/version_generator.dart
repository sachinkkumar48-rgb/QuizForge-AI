// ignore_for_file: avoid_print
import 'dart:io';

/// Automated semantic version generator for Project TITAN releases.
void main(List<String> args) {
  final version = args.isNotEmpty ? args[0] : '2.0.0-beta.1';
  final buildNumber = args.length > 1 ? args[1] : '100';

  print('====================================');
  print('TITAN Release Version Generator');
  print('Generating Version: $version+$buildNumber');
  print('====================================');

  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    var content = pubspecFile.readAsStringSync();
    content = content.replaceFirst(
      RegExp(r'version:\s*[^\n]+'),
      'version: $version+$buildNumber',
    );
    pubspecFile.writeAsStringSync(content);
    print('Successfully updated pubspec.yaml version to $version+$buildNumber');
  } else {
    print('Warning: pubspec.yaml not found in current directory.');
  }
}
