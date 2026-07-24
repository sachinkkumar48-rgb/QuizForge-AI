/// Exception thrown when configuration validation fails during startup.
class TitanInvalidConfigException implements Exception {
  final String reason;

  const TitanInvalidConfigException(this.reason);

  @override
  String toString() => 'TitanInvalidConfigException: $reason';
}
