import 'titan_config.dart';
import 'titan_environment.dart';

/// Service responsible for loading, constructing, and validating [TitanConfig] instances.
class TitanConfigLoader {
  const TitanConfigLoader();

  /// Loads, constructs, and validates configuration for the target environment.
  /// Throws [TitanInvalidConfigException] if configuration is invalid.
  Future<TitanConfig> load({
    TitanEnvironment environment = TitanEnvironment.development,
    TitanConfig? overrideConfig,
  }) async {
    final config =
        overrideConfig ?? TitanConfig.defaultConfig(environment: environment);
    config.validate();
    return config;
  }
}
