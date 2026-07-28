import 'package:test/test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Forecast Tests', () {
    late LearningJourneyEngine engine;

    setUp(() {
      engine = const LearningJourneyEngine();
    });

    test(
        'calculateForecast adjusts readiness probability with overall progress',
        () {
      final config = JourneyConfiguration(
        journeyId: 'j_fc_1',
        targetExam: 'UPSC CSE 2026',
        targetExamDate: DateTime.now().add(const Duration(days: 100)),
        dailyTimeBudgetMinutes: 120,
        targetConfidenceScore: 0.85,
      );

      final progress = JourneyProgress(
        journeyId: 'j_fc_1',
        overallProgress: 0.90,
        completedMilestonesCount: 9,
        totalMilestonesCount: 10,
        completedTasksCount: 18,
        totalTasksCount: 20,
        weeklyVelocityMinutes: 700,
        streakDays: 14,
        lastActiveAt: DateTime.now(),
      );

      const health = JourneyHealth(
        journeyId: 'j_fc_1',
        score: 92.0,
        level: HealthLevel.excellent,
        consistencyScore: 95.0,
        retentionScore: 90.0,
        assessmentReadinessScore: 90.0,
        activityPaceScore: 90.0,
      );

      final forecast = engine.calculateForecast(
        journeyId: 'j_fc_1',
        config: config,
        progress: progress,
        health: health,
      );

      expect(forecast.examReadinessProbability, greaterThanOrEqualTo(0.80));
      expect(forecast.projectedFinalScore, greaterThanOrEqualTo(80.0));
      expect(forecast.forecastSummary, contains('High readiness probability'));
    });
  });
}
