import 'package:meta/meta.dart';
import 'titan_log_level.dart';

/// Immutable model representing a single structured log event in Project TITAN.
@immutable
class TitanLogEntry {
  final DateTime timestamp;
  final TitanLogLevel level;
  final String message;
  final String? tag;
  final Object? exception;
  final StackTrace? stackTrace;

  /// Generative constructor defaulting [timestamp] to current time if unprovided.
  TitanLogEntry({
    required this.level,
    required this.message,
    this.tag,
    Object? exception,
    Object? error,
    this.stackTrace,
    DateTime? timestamp,
  })  : exception = exception ?? error,
        timestamp = timestamp ?? DateTime.now();

  /// Immutable const constructor requiring explicit [timestamp].
  const TitanLogEntry.constEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.exception,
    this.stackTrace,
  });

  /// Legacy error alias for backward compatibility.
  Object? get error => exception;

  @override
  String toString() {
    final tagStr = tag != null && tag!.isNotEmpty ? '[$tag] ' : '';
    final excStr = exception != null ? '\nException: $exception' : '';
    final stStr = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    return '[${timestamp.toIso8601String()}] [${level.name.toUpperCase()}] $tagStr$message$excStr$stStr';
  }
}
