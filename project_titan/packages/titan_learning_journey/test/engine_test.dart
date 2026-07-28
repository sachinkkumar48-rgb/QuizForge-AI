import 'package:test/test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Engine Pure Dart Tests', () {
    late LearningJourneyEngine engine;

    setUp(() {
      engine = const LearningJourneyEngine();
    });

    test('generateRoadmap creates 4 stages with initial progress & health', () {
      final config = JourneyConfiguration(
        journeyId: 'j_eng_1',
        targetExam: 'UPSC CSE 2026',
        targetExamDate: DateTime.now().add(const Duration(days: 180)),
        dailyTimeBudgetMinutes: 120,
        targetConfidenceScore: 0.85,
      );

      final journey = engine.generateRoadmap(
        learnerId: 'learner_101',
        config: config,
      );

      expect(journey.stages.length, equals(4));
      expect(journey.stages[0].status, equals(JourneyStageStatus.inProgress));
      expect(journey.stages[1].status, equals(JourneyStageStatus.locked));
      expect(journey.health.score, greaterThan(0.0));
      expect(journey.forecast.examReadinessProbability, greaterThan(0.0));
    });

    test('calculateHealth evaluates health factors correctly', () {
      final progress = JourneyProgress(
        journeyId: 'j1',
        overallProgress: 0.80,
        completedMilestonesCount: 4,
        totalMilestonesCount: 5,
        completedTasksCount: 12,
        totalTasksCount: 15,
        weeklyVelocityMinutes: 500,
        streakDays: 10,
        lastActiveAt: DateTime.now(),
      );

      final health = engine.calculateHealth(
        journeyId: 'j1',
        progress: progress,
        averageAssessmentScore: 85.0,
        revisionRetentionRate: 0.90,
      );

      expect(health.score, greaterThan(80.0));
      expect(health.level, equals(HealthLevel.excellent));
      expect(health.healthFactors, contains('High study streak & consistency'));
    });
  });
}
