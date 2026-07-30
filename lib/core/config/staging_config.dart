import 'app_config.dart';

/// Staging environment configuration profile for Project TITAN.
class StagingConfig extends AppConfig {
  const StagingConfig({
    super.apiBaseUrl = 'http://161.118.179.119:8000',
    super.requestTimeout = const Duration(seconds: 20),
    super.maxRetries = 3,
    super.initialRetryDelay = const Duration(milliseconds: 300),
    super.loggingEnabled = true,
    super.featureFlags = const {
      'enable_mock_data': false,
      'enable_debug_overlay': true,
      'enable_experimental_ai': true,
    },
  }) : super(environment: Environment.staging);
}
