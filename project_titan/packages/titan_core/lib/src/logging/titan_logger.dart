import '../error/error_reporter.dart';
import 'log_sink.dart';
import 'titan_log_entry.dart';
import 'titan_log_level.dart';

/// Logging abstraction for Project TITAN supporting log level filtering and error reporting.
abstract class TitanLogger {
  /// Minimum log level configured for this logger instance.
  TitanLogLevel get minLogLevel;

  /// Log a trace message.
  void trace(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]);

  /// Log a debug message.
  void debug(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]);

  /// Log an info message.
  void info(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]);

  /// Log a warning message.
  void warning(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]);

  /// Log an error message.
  void error(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]);

  /// Log a critical error message.
  void critical(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]);

  /// Process a structured [TitanLogEntry].
  void log(TitanLogEntry entry);
}

/// Standard implementation of [TitanLogger] delegating formatted output to [LogSink].
class ConsoleTitanLogger implements TitanLogger {
  @override
  final TitanLogLevel minLogLevel;
  final LogSink logSink;
  final ErrorReporter errorReporter;

  ConsoleTitanLogger({
    this.minLogLevel = TitanLogLevel.trace,
    LogSink? logSink,
    ErrorReporter? errorReporter,
    bool enableDebugPrints = true,
  })  : logSink = logSink ?? const ConsoleLogSink(),
        errorReporter = errorReporter ?? const NoOpErrorReporter();

  @override
  void log(TitanLogEntry entry) {
    if (entry.level.priority < minLogLevel.priority) return;

    logSink.write(entry);

    if (entry.level >= TitanLogLevel.error) {
      errorReporter.report(entry);
    }
  }

  void _createAndLog(
    TitanLogLevel level,
    String message, [
    Object? exception,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    log(TitanLogEntry(
      level: level,
      message: message,
      exception: exception,
      stackTrace: stackTrace,
      tag: tag,
    ));
  }

  @override
  void trace(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]) {
    _createAndLog(TitanLogLevel.trace, message, exception, stackTrace, tag);
  }

  @override
  void debug(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]) {
    _createAndLog(TitanLogLevel.debug, message, exception, stackTrace, tag);
  }

  @override
  void info(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]) {
    _createAndLog(TitanLogLevel.info, message, exception, stackTrace, tag);
  }

  @override
  void warning(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]) {
    _createAndLog(TitanLogLevel.warning, message, exception, stackTrace, tag);
  }

  @override
  void error(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]) {
    _createAndLog(TitanLogLevel.error, message, exception, stackTrace, tag);
  }

  @override
  void critical(String message,
      [Object? exception, StackTrace? stackTrace, String? tag]) {
    _createAndLog(TitanLogLevel.critical, message, exception, stackTrace, tag);
  }
}
