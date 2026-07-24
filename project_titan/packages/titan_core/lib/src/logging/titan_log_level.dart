import '../config/titan_environment.dart';

/// Strongly typed log levels with priority ordering for Project TITAN observability.
enum TitanLogLevel implements Comparable<TitanLogLevel> {
  trace(0),
  debug(1),
  info(2),
  warning(3),
  error(4),
  critical(5);

  final int priority;
  const TitanLogLevel(this.priority);

  bool operator >=(TitanLogLevel other) => priority >= other.priority;
  bool operator <=(TitanLogLevel other) => priority <= other.priority;
  bool operator >(TitanLogLevel other) => priority > other.priority;
  bool operator <(TitanLogLevel other) => priority < other.priority;

  @override
  int compareTo(TitanLogLevel other) => priority.compareTo(other.priority);

  /// Returns recommended minimum log level per environment.
  static TitanLogLevel defaultForEnvironment(TitanEnvironment env) {
    switch (env) {
      case TitanEnvironment.development:
        return TitanLogLevel.trace;
      case TitanEnvironment.staging:
        return TitanLogLevel.debug;
      case TitanEnvironment.production:
        return TitanLogLevel.warning;
      case TitanEnvironment.testing:
        return TitanLogLevel.info;
    }
  }
}
