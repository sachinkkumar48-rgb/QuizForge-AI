import 'app_config.dart';

/// Development environment configuration profile for Project TITAN.
class DevelopmentConfig extends AppConfig {
  const DevelopmentConfig({
    super.apiBaseUrl = AppConfig.defaultApiBaseUrl,
    super.requestTimeout = const Duration(seconds: 30),
    super.maxRetries = 3,
    super.initialRetryDelay = const Duration(milliseconds: 500),
    super.loggingEnabled = true,
    super.featureFlags = const {
      'enable_mock_data': true,
      'enable_debug_overlay': true,
      'enable_experimental_ai': true,
    },
  }) : super(environment: Environment.development);
}
