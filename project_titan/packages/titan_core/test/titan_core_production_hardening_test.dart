import 'package:flutter_test/flutter_test.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  group('Titan Core Production Hardening Unit Tests', () {
    test('FeatureFlagService exposes 8 default beta flags', () {
      final flags = FeatureFlagService();
      expect(flags.getAllFlags().keys.length, equals(8));
      expect(flags.videoClasses, isFalse);
      expect(flags.voiceMentor, isTrue);
      expect(flags.aiTutor, isTrue);
      expect(flags.gamification, isTrue);

      flags.setFlag('video_classes', true);
      expect(flags.videoClasses, isTrue);
    });

    test('CrashReport creation and serialization', () {
      final report = CrashReport(
        id: 'c_1',
        errorMessage: 'Network timeout',
        errorType: 'network',
      );

      expect(report.id, equals('c_1'));
      expect(report.errorMessage, equals('Network timeout'));

      final json = report.toJson();
      final restored = CrashReport.fromJson(json);
      expect(restored.errorMessage, equals('Network timeout'));
    });

    test('HealthMonitor executes checkers and reports operational status',
        () async {
      final monitor = HealthMonitor();
      monitor.registerChecker(
        'storage',
        () => SubsystemHealth(
          name: 'storage',
          status: HealthStatus.healthy,
          message: 'Hive storage active',
        ),
      );

      final health = await monitor.checkHealth();
      expect(health.containsKey('storage'), isTrue);
      expect(health['storage']!.status, equals(HealthStatus.healthy));
      expect(await monitor.isSystemOperational(), isTrue);
    });
  });
}
