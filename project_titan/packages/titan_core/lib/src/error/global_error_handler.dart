import 'package:flutter/foundation.dart';

import '../logging/titan_log_entry.dart';
import '../logging/titan_log_level.dart';
import '../logging/titan_logger.dart';
import 'error_reporter.dart';
import 'titan_error.dart';
import 'titan_error_type.dart';

/// Alias for TitanErrorHandler.
typedef GlobalErrorHandler = TitanErrorHandler;

/// Central global error handler classifying framework, asynchronous, and uncaught exceptions.
class TitanErrorHandler {
  final TitanLogger logger;
  final ErrorReporter errorReporter;

  TitanErrorHandler({
    required this.logger,
    ErrorReporter? errorReporter,
  }) : errorReporter = errorReporter ?? const NoOpErrorReporter();

  /// Attach global Flutter framework and platform asynchronous error hooks.
  void initialize() {
    FlutterError.onError = handleFrameworkError;

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
      handleAsynchronousError(error, stackTrace);
      return true; // Error handled
    };
  }

  /// Classify, log, and report Flutter framework errors.
  TitanError captureFrameworkError(FlutterErrorDetails details) {
    final titanError = TitanError(
      errorType: TitanErrorType.framework,
      exception: details.exception,
      stackTrace: details.stack,
      message: 'Flutter Framework Error: ${details.summary}',
    );

    final logEntry = TitanLogEntry(
      level: TitanLogLevel.critical,
      message: titanError.message,
      tag: 'FrameworkError',
      exception: titanError.exception,
      stackTrace: titanError.stackTrace,
      timestamp: titanError.timestamp,
    );

    logger.log(logEntry);
    errorReporter.report(logEntry);

    return titanError;
  }

  /// Classify, log, and report uncaught asynchronous platform errors.
  TitanError captureAsyncError(Object error, StackTrace stackTrace) {
    final titanError = TitanError(
      errorType: TitanErrorType.async,
      exception: error,
      stackTrace: stackTrace,
      message: 'Asynchronous Platform Error',
    );

    final logEntry = TitanLogEntry(
      level: TitanLogLevel.critical,
      message: titanError.message,
      tag: 'AsyncPlatformError',
      exception: titanError.exception,
      stackTrace: titanError.stackTrace,
      timestamp: titanError.timestamp,
    );

    logger.log(logEntry);
    errorReporter.report(logEntry);

    return titanError;
  }

  /// Classify, log, and report uncaught application exceptions.
  TitanError captureUncaughtError(
    Object exception,
    StackTrace stackTrace, [
    String? contextName,
    TitanErrorType? customType,
  ]) {
    final tag = contextName ?? 'UncaughtException';
    final errorType = customType ?? TitanErrorType.uncaught;

    final titanError = TitanError(
      errorType: errorType,
      exception: exception,
      stackTrace: stackTrace,
      message: 'Uncaught Exception in [$tag]',
    );

    final logEntry = TitanLogEntry(
      level: TitanLogLevel.error,
      message: titanError.message,
      tag: tag,
      exception: titanError.exception,
      stackTrace: titanError.stackTrace,
      timestamp: titanError.timestamp,
    );

    logger.log(logEntry);
    errorReporter.report(logEntry);

    return titanError;
  }

  /// Backward-compatible alias for framework error handling.
  void handleFrameworkError(FlutterErrorDetails details) {
    captureFrameworkError(details);
  }

  /// Backward-compatible alias for asynchronous error handling.
  void handleAsynchronousError(Object error, StackTrace stackTrace) {
    captureAsyncError(error, stackTrace);
  }

  /// Backward-compatible alias for uncaught exception handling.
  void handleUncaughtException(
    Object exception,
    StackTrace stackTrace, [
    String? contextName,
  ]) {
    captureUncaughtError(exception, stackTrace, contextName);
  }
}
