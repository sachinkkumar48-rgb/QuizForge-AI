import 'package:meta/meta.dart';
import 'titan_error_type.dart';

/// Immutable model representing a classified application error in Project TITAN.
@immutable
class TitanError {
  final TitanErrorType errorType;
  final Object exception;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final String message;

  /// Generative constructor defaulting [timestamp] to current time if unprovided.
  TitanError({
    required this.errorType,
    required this.exception,
    this.stackTrace,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Immutable const constructor requiring explicit [timestamp].
  const TitanError.constError({
    required this.errorType,
    required this.exception,
    this.stackTrace,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'TitanError[${errorType.name}]: $message (${exception.runtimeType}: $exception)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitanError &&
          runtimeType == other.runtimeType &&
          errorType == other.errorType &&
          exception == other.exception &&
          stackTrace == other.stackTrace &&
          timestamp == other.timestamp &&
          message == other.message;

  @override
  int get hashCode =>
      errorType.hashCode ^
      exception.hashCode ^
      stackTrace.hashCode ^
      timestamp.hashCode ^
      message.hashCode;
}
