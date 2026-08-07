/// Environment mode enum for Project TITAN.
enum Environment { development, staging, production }

/// Centralized application configuration base class for Project TITAN.
class AppConfig {
  /// Target runtime environment profile.
  final Environment environment;

  /// Base URL for the FastAPI backend server.
  final String apiBaseUrl;

  /// Maximum duration to wait for an HTTP request before timing out.
  final Duration requestTimeout;

  /// Maximum number of attempts for retrying transient network failures.
  final int maxRetries;

  /// Initial delay duration for exponential backoff during retries.
  final Duration initialRetryDelay;

  /// Flag to enable or disable debug logging.
  final bool loggingEnabled;

  /// Feature flags map for toggling dynamic application capabilities.
  final Map<String, bool> featureFlags;

  /// Default backend base URL for Project TITAN, configurable via `--dart-define=API_BASE_URL=...`.
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://161.118.179.119:8000',
  );

  const AppConfig({
    this.environment = Environment.development,
    this.apiBaseUrl = defaultApiBaseUrl,
    this.requestTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.initialRetryDelay = const Duration(milliseconds: 500),
    this.loggingEnabled = true,
    this.featureFlags = const {},
  });

  /// Default configuration instance.
  static const AppConfig defaultConfig = AppConfig();

  /// Helper to check if a specific feature flag is enabled.
  bool isFeatureEnabled(String flagKey) => featureFlags[flagKey] ?? false;

  /// Creates a copy of [AppConfig] with updated field values.
  AppConfig copyWith({
    Environment? environment,
    String? apiBaseUrl,
    Duration? requestTimeout,
    int? maxRetries,
    Duration? initialRetryDelay,
    bool? loggingEnabled,
    Map<String, bool>? featureFlags,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      initialRetryDelay: initialRetryDelay ?? this.initialRetryDelay,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
      featureFlags: featureFlags ?? this.featureFlags,
    );
  }
}
