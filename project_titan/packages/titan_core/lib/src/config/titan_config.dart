import 'package:meta/meta.dart';

import 'config_exceptions.dart';
import 'titan_environment.dart';

/// Immutable, strongly typed application configuration container for Project TITAN.
@immutable
class TitanConfig {
  final TitanEnvironment titanEnvironment;
  final String appName;
  final String version;
  final int buildNumber;
  final bool isDebug;
  final Map<String, bool> _featureFlags;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableAnalytics;
  final String aiApiKey;
  final String aiDefaultModel;
  final Duration aiTimeout;
  final Duration repositoryCacheTtl;
  final bool enableRepositoryCaching;

  TitanConfig({
    required this.titanEnvironment,
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.isDebug,
    required Map<String, bool> featureFlags,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.enableAnalytics,
    this.aiApiKey = '',
    this.aiDefaultModel = 'gemini-1.5-flash',
    this.aiTimeout = const Duration(seconds: 30),
    this.repositoryCacheTtl = const Duration(minutes: 15),
    this.enableRepositoryCaching = true,
  }) : _featureFlags = Map<String, bool>.unmodifiable(featureFlags);

  /// Backward-compatible String representation of environment.
  String get environment => titanEnvironment.value;

  /// Read-only access to feature flags map.
  Map<String, bool> get featureFlags => _featureFlags;

  /// Check if a specific feature flag key is enabled.
  bool isFeatureEnabled(String key) {
    return _featureFlags[key] ?? false;
  }

  /// Validates configuration integrity, throwing [TitanInvalidConfigException] if invalid.
  void validate() {
    if (appName.trim().isEmpty) {
      throw const TitanInvalidConfigException('appName cannot be empty.');
    }
    if (version.trim().isEmpty) {
      throw const TitanInvalidConfigException('version cannot be empty.');
    }
    if (buildNumber < 0) {
      throw const TitanInvalidConfigException(
          'buildNumber cannot be negative.');
    }
    if (apiBaseUrl.trim().isEmpty) {
      throw const TitanInvalidConfigException('apiBaseUrl cannot be empty.');
    }
    if (aiTimeout.isNegative || aiTimeout == Duration.zero) {
      throw const TitanInvalidConfigException(
          'aiTimeout must be greater than zero.');
    }
    if (repositoryCacheTtl.isNegative || repositoryCacheTtl == Duration.zero) {
      throw const TitanInvalidConfigException(
          'repositoryCacheTtl must be greater than zero.');
    }
  }

  /// Default configuration factory preserving backward compatibility.
  factory TitanConfig.defaultConfig({
    TitanEnvironment environment = TitanEnvironment.development,
    String aiApiKey = '',
    String aiDefaultModel = 'gemini-1.5-flash',
    Duration aiTimeout = const Duration(seconds: 30),
    Duration repositoryCacheTtl = const Duration(minutes: 15),
    bool enableRepositoryCaching = true,
  }) {
    return TitanConfig(
      titanEnvironment: environment,
      appName: 'QuizForge AI',
      version: '1.0.0',
      buildNumber: 1,
      isDebug: environment != TitanEnvironment.production,
      featureFlags: const {
        'enable_ai_tutor': true,
        'enable_analytics': true,
        'enable_spaced_repetition': true,
        'enable_cloud_sync': false,
      },
      apiBaseUrl: environment.isProduction
          ? 'https://api.quizforge.ai'
          : 'https://api-dev.quizforge.ai',
      enableLogging: environment != TitanEnvironment.production,
      enableAnalytics: environment != TitanEnvironment.testing,
      aiApiKey: aiApiKey,
      aiDefaultModel: aiDefaultModel,
      aiTimeout: aiTimeout,
      repositoryCacheTtl: repositoryCacheTtl,
      enableRepositoryCaching: enableRepositoryCaching,
    );
  }
}
