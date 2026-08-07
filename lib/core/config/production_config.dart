import 'app_config.dart';

/// Production environment configuration profile for Project TITAN.
class ProductionConfig extends AppConfig {
  const ProductionConfig({
    super.apiBaseUrl = AppConfig.defaultApiBaseUrl,
    super.requestTimeout = const Duration(seconds: 15),
    super.maxRetries = 3,
    super.initialRetryDelay = const Duration(milliseconds: 250),
    super.loggingEnabled = false,
    super.featureFlags = const {
      'enable_mock_data': false,
      'enable_debug_overlay': false,
      'enable_experimental_ai': false,
    },
  }) : super(environment: Environment.production);
}
