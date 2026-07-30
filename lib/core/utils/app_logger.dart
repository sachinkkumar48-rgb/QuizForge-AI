import 'package:flutter/foundation.dart';

/// Lightweight structured logger utility for Project TITAN.
class AppLogger {
  AppLogger._();

  /// Global toggle for logging enablement.
  static bool loggingEnabled = true;

  /// Logs debug level messages when running in debug mode and logging is enabled.
  static void debug(String message, {String? tag}) {
    if (kDebugMode && loggingEnabled) {
      final prefix = tag != null ? '[$tag]' : '[DEBUG]';
      debugPrint('$prefix $message');
    }
  }

  /// Logs info level messages when running in debug mode and logging is enabled.
  static void info(String message, {String? tag}) {
    if (kDebugMode && loggingEnabled) {
      final prefix = tag != null ? '[$tag]' : '[INFO]';
      debugPrint('$prefix $message');
    }
  }

  /// Logs error level messages with optional error object and stack trace.
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode && loggingEnabled) {
      final prefix = tag != null ? '[$tag]' : '[ERROR]';
      debugPrint('$prefix $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('  StackTrace: $stackTrace');
      }
    }
  }
}
