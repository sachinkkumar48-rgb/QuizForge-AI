import 'package:test/test.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';

void main() {
  group('Domain Models Tests', () {
    test('JourneyConfiguration serialization & immutability', () {
      final config = JourneyConfiguration(
        journeyId: 'j_01',
        targetExam: 'UPSC CSE 2026',
        targetExamDate: DateTime(2026, 6, 1),
        dailyTimeBudgetMinutes: 120,
        targetConfidenceScore: 0.85,
      );

      final json = config.toJson();
      final restored = JourneyConfiguration.fromJson(json);

      expect(restored.journeyId, equals('j_01'));
      expect(restored.targetExam, equals('UPSC CSE 2026'));
      expect(restored.dailyTimeBudgetMinutes, equals(120));
      expect(restored, equals(config));
    });

    test('JourneyTask copyWith and status updates', () {
      const task = JourneyTask(
        id: 't1',
        title: 'Read Chapter 1',
        description: 'Polity basics',
        moduleSource: 'titan_academy',
        resourceId: 'r1',
        estimatedMinutes: 45,
      );

      expect(task.status, equals(TaskStatus.todo));

      final updated = task.copyWith(status: TaskStatus.completed);
      expect(updated.status, equals(TaskStatus.completed));
      expect(updated.id, equals(task.id));
    });

    test('JourneyHealth equality and hashCode', () {
      const h1 = JourneyHealth(
        journeyId: 'j1',
        score: 85.0,
        level: HealthLevel.good,
        consistencyScore: 90.0,
        retentionScore: 80.0,
        assessmentReadinessScore: 85.0,
        activityPaceScore: 85.0,
      );

      const h2 = JourneyHealth(
        journeyId: 'j1',
        score: 85.0,
        level: HealthLevel.good,
        consistencyScore: 90.0,
        retentionScore: 80.0,
        assessmentReadinessScore: 85.0,
        activityPaceScore: 85.0,
      );

      expect(h1, equals(h2));
      expect(h1.hashCode, equals(h2.hashCode));
    });
  });
}
