/// Strongly typed deployment environments supported in Project TITAN.
enum TitanEnvironment {
  development('development'),
  staging('staging'),
  production('production'),
  testing('testing');

  final String value;
  const TitanEnvironment(this.value);

  bool get isDevelopment => this == TitanEnvironment.development;
  bool get isStaging => this == TitanEnvironment.staging;
  bool get isProduction => this == TitanEnvironment.production;
  bool get isTesting => this == TitanEnvironment.testing;

  /// Parse environment string into [TitanEnvironment] with fallback.
  static TitanEnvironment fromString(String envString) {
    return TitanEnvironment.values.firstWhere(
      (e) => e.value.toLowerCase() == envString.toLowerCase(),
      orElse: () => TitanEnvironment.development,
    );
  }
}
