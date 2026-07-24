import '../logging/titan_log_entry.dart';

/// Abstract Error Reporter contract for forwarding critical log entries in Project TITAN.
abstract class ErrorReporter {
  /// Report a log entry (typically error or critical level).
  void report(TitanLogEntry entry);
}

/// Default no-op implementation of [ErrorReporter] used when no external reporting service is attached.
class NoOpErrorReporter implements ErrorReporter {
  const NoOpErrorReporter();

  @override
  void report(TitanLogEntry entry) {
    // No-op by design
  }
}
