import 'dart:io';

/// Security utility that validates and sanitizes attachment filenames to prevent path traversal,
/// filesystem escape, control character injection, and Windows reserved device name exploits.
class PdfFilenameSanitizer {
  /// Windows reserved device names that cannot be used as standalone file base names.
  static const Set<String> _reservedDeviceNames = {
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };

  /// Sanitizes an untrusted filename extracted from a PDF document.
  ///
  /// Returns a clean, safe basename without path components or malicious tokens.
  static String sanitize(String? rawFilename,
      {String fallback = 'attachment.bin'}) {
    if (rawFilename == null || rawFilename.trim().isEmpty) {
      return fallback;
    }

    var name = rawFilename.trim();

    // 1. Remove null bytes and control characters (ASCII 0x00 - 0x1F, 0x7F)
    final buffer = StringBuffer();
    for (var i = 0; i < name.length; i++) {
      final code = name.codeUnitAt(i);
      if (code >= 32 && code != 127) {
        buffer.writeCharCode(code);
      }
    }
    name = buffer.toString();

    // 2. Strip leading/trailing UNC or drive letter prefixes (e.g. `C:\`, `\\server\share\`)
    name = name.replaceAll(RegExp(r'^[a-zA-Z]:[/\\]+'), '');
    name = name.replaceAll(RegExp(r'^[/\\]+'), '');

    // 3. Extract only the last path component (strip any directory traversal `../` or `..\`)
    final lastSlash = name.lastIndexOf(RegExp(r'[/\\]'));
    if (lastSlash != -1) {
      name = name.substring(lastSlash + 1);
    }

    // 4. Replace prohibited filesystem characters: : * ? " < > | / \ with underscore
    name = name.replaceAll(RegExp(r'[:*?"<>|/\\]'), '_');

    // 5. Strip leading and trailing periods and whitespace
    name = name.replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');

    if (name.isEmpty) {
      return fallback;
    }

    // 6. Check for Windows reserved device names (e.g. CON.txt -> CON_file.txt)
    final dotIdx = name.indexOf('.');
    final baseNameUpper =
        (dotIdx != -1 ? name.substring(0, dotIdx) : name).toUpperCase();
    if (_reservedDeviceNames.contains(baseNameUpper)) {
      if (dotIdx != -1) {
        name = '${name.substring(0, dotIdx)}_file${name.substring(dotIdx)}';
      } else {
        name = '${name}_file';
      }
    }

    return name.isEmpty ? fallback : name;
  }

  /// Resolves a safe destination file path inside [destinationDirectoryPath].
  ///
  /// Guarantees that the resulting file path is strictly located within [destinationDirectoryPath].
  /// If [overwrite] is false and a file already exists at the destination, appends an incrementing counter:
  /// `filename (1).ext`, `filename (2).ext`, etc.
  static String resolveSafeDestinationPath({
    required String destinationDirectoryPath,
    required String desiredFilename,
    bool overwrite = false,
    bool Function(String path)? fileExists,
  }) {
    final cleanName = sanitize(desiredFilename);
    final normalizedDir = destinationDirectoryPath
        .replaceAll(r'\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    final checkExists = fileExists ?? (String p) => File(p).existsSync();

    var candidatePath = '$normalizedDir/$cleanName';
    if (overwrite || !checkExists(candidatePath)) {
      return candidatePath;
    }

    // Break name into base and extension for collision incrementing
    final dotIndex = cleanName.lastIndexOf('.');
    final base =
        (dotIndex != -1) ? cleanName.substring(0, dotIndex) : cleanName;
    final ext = (dotIndex != -1) ? cleanName.substring(dotIndex) : '';

    var counter = 1;
    while (checkExists('$normalizedDir/$base ($counter)$ext')) {
      counter++;
      if (counter > 1000) break; // Prevent runaway loop
    }

    return '$normalizedDir/$base ($counter)$ext';
  }
}
