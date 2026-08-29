import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/study_time_budget.dart';

void main() {
  group('StudyTimeBudget Entity Tests (TITAN-KO-024.0 P24)', () {
    final fixedTime = DateTime.utc(2026, 8, 27, 10, 0, 0);

    test('1. Valid construction with valid parameters', () {
      final budget = StudyTimeBudget(
        learnerId: 'learner_100',
        dailyAvailableMinutes: 60,
        preferredSessionDurationMinutes: 20,
        maxSessionsPerDay: 3,
        effectiveFrom: fixedTime,
      );

      expect(budget.learnerId, equals('learner_100'));
      expect(budget.dailyAvailableMinutes, equals(60));
      expect(budget.preferredSessionDurationMinutes, equals(20));
      expect(budget.maxSessionsPerDay, equals(3));
      expect(budget.effectiveFrom, equals(fixedTime));
      expect(budget.effectiveDailyCapacityMinutes, equals(60));
    });

    test('2. Rejects empty learnerId', () {
      expect(
        () => StudyTimeBudget(
          learnerId: '   ',
          dailyAvailableMinutes: 60,
          preferredSessionDurationMinutes: 20,
          maxSessionsPerDay: 3,
          effectiveFrom: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('3. Rejects invalid dailyAvailableMinutes (< 1 or > 480)', () {
      expect(
        () => StudyTimeBudget(
          learnerId: 'learner_100',
          dailyAvailableMinutes: 0,
          preferredSessionDurationMinutes: 20,
          maxSessionsPerDay: 3,
          effectiveFrom: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => StudyTimeBudget(
          learnerId: 'learner_100',
          dailyAvailableMinutes: 481,
          preferredSessionDurationMinutes: 20,
          maxSessionsPerDay: 3,
          effectiveFrom: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('4. Rejects preferredSessionDurationMinutes < minSessionMinutes (5)',
        () {
      expect(
        () => StudyTimeBudget(
          learnerId: 'learner_100',
          dailyAvailableMinutes: 60,
          preferredSessionDurationMinutes: 4,
          maxSessionsPerDay: 3,
          effectiveFrom: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('5. Rejects preferredSessionDurationMinutes > dailyAvailableMinutes',
        () {
      expect(
        () => StudyTimeBudget(
          learnerId: 'learner_100',
          dailyAvailableMinutes: 30,
          preferredSessionDurationMinutes: 45,
          maxSessionsPerDay: 1,
          effectiveFrom: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('6. Rejects maxSessionsPerDay < 1', () {
      expect(
        () => StudyTimeBudget(
          learnerId: 'learner_100',
          dailyAvailableMinutes: 60,
          preferredSessionDurationMinutes: 20,
          maxSessionsPerDay: 0,
          effectiveFrom: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test(
        '7. Calculates effectiveDailyCapacityMinutes clamped to dailyAvailableMinutes',
        () {
      final budget = StudyTimeBudget(
        learnerId: 'learner_100',
        dailyAvailableMinutes: 100,
        preferredSessionDurationMinutes: 25,
        maxSessionsPerDay: 2,
        effectiveFrom: fixedTime,
      );
      // 2 sessions * 25min = 50min, which is < 100min available
      expect(budget.effectiveDailyCapacityMinutes, equals(50));

      final budget2 = StudyTimeBudget(
        learnerId: 'learner_100',
        dailyAvailableMinutes: 60,
        preferredSessionDurationMinutes: 25,
        maxSessionsPerDay: 4,
        effectiveFrom: fixedTime,
      );
      // 4 sessions * 25min = 100min, clamped to 60min dailyAvailableMinutes
      expect(budget2.effectiveDailyCapacityMinutes, equals(60));
    });

    test('8. JSON serialization and deserialization roundtrip', () {
      final budget = StudyTimeBudget(
        learnerId: 'learner_100',
        dailyAvailableMinutes: 90,
        preferredSessionDurationMinutes: 30,
        maxSessionsPerDay: 3,
        effectiveFrom: fixedTime,
        metadata: {'policy': 'standard'},
      );

      final json = budget.toJson();
      final restored = StudyTimeBudget.fromJson(json);

      expect(restored, equals(budget));
      expect(restored.hashCode, equals(budget.hashCode));
      expect(restored.metadata['policy'], equals('standard'));
    });
  });
}
