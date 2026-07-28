import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('Adaptive Teaching Logic Tests', () {
    late TutorEngine engine;

    setUp(() {
      engine = const TutorEngine();
    });

    test('Difficulty increases on high performance streak', () {
      const initial = TutorDifficulty(
        currentLevel: TutorDifficultyLevel.intermediate,
        numericScale: 5.0,
      );

      final adapted = engine.adjustDifficulty(
        current: initial,
        lastScore: 90.0,
        consecutiveSuccesses: 2,
      );

      expect(adapted.numericScale, equals(6.0));
      expect(adapted.adaptReason, contains('Increased difficulty'));
    });

    test('Difficulty decreases on low performance', () {
      const initial = TutorDifficulty(
        currentLevel: TutorDifficultyLevel.intermediate,
        numericScale: 5.0,
      );

      final adapted = engine.adjustDifficulty(
        current: initial,
        lastScore: 40.0,
        consecutiveSuccesses: 0,
      );

      expect(adapted.numericScale, equals(4.0));
      expect(adapted.adaptReason, contains('Scaffolded difficulty'));
    });

    test('Confidence estimation drops with hint usage and long response time',
        () {
      final highConf = engine.estimateConfidence(
        hintsUsed: 0,
        score: 95.0,
        responseTimeSeconds: 30,
      );

      final lowConf = engine.estimateConfidence(
        hintsUsed: 3,
        score: 60.0,
        responseTimeSeconds: 150,
      );

      expect(highConf, greaterThan(lowConf));
      expect(lowConf, lessThan(0.5));
    });
  });
}
