import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/core/config/app_config.dart';
import 'package:quizforge_upsc/core/config/development_config.dart';
import 'package:quizforge_upsc/core/config/production_config.dart';
import 'package:quizforge_upsc/core/config/staging_config.dart';

void main() {
  group('Environment Profiles Configuration Tests', () {
    test('DevelopmentConfig initializes with correct development values', () {
      const config = DevelopmentConfig();

      expect(config.environment, equals(Environment.development));
      expect(config.apiBaseUrl, equals('http://161.118.179.119:8000'));
      expect(config.requestTimeout, equals(const Duration(seconds: 30)));
      expect(config.maxRetries, equals(3));
      expect(config.loggingEnabled, isTrue);
      expect(config.isFeatureEnabled('enable_mock_data'), isTrue);
      expect(config.isFeatureEnabled('enable_debug_overlay'), isTrue);
    });

    test('StagingConfig initializes with correct staging values', () {
      const config = StagingConfig();

      expect(config.environment, equals(Environment.staging));
      expect(config.requestTimeout, equals(const Duration(seconds: 20)));
      expect(config.maxRetries, equals(3));
      expect(config.loggingEnabled, isTrue);
      expect(config.isFeatureEnabled('enable_mock_data'), isFalse);
      expect(config.isFeatureEnabled('enable_debug_overlay'), isTrue);
    });

    test('ProductionConfig initializes with correct production values', () {
      const config = ProductionConfig();

      expect(config.environment, equals(Environment.production));
      expect(config.requestTimeout, equals(const Duration(seconds: 15)));
      expect(config.maxRetries, equals(3));
      expect(config.loggingEnabled, isFalse);
      expect(config.isFeatureEnabled('enable_mock_data'), isFalse);
      expect(config.isFeatureEnabled('enable_debug_overlay'), isFalse);
    });

    test('AppConfig copyWith updates specific values correctly', () {
      const config = DevelopmentConfig();
      final updated = config.copyWith(
        apiBaseUrl: 'http://custom-dev:8000',
        loggingEnabled: false,
      );

      expect(updated.apiBaseUrl, equals('http://custom-dev:8000'));
      expect(updated.loggingEnabled, isFalse);
      expect(updated.environment, equals(Environment.development));
      expect(updated.maxRetries, equals(3));
    });
  });
}
