import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/study_plan_request.dart';
import 'package:garuda_learning/domain/entities/study_time_budget.dart';

void main() {
  group('StudyPlanRequest Entity Tests (TITAN-KO-024.0 P24)', () {
    final fixedTime = DateTime.utc(2026, 8, 27, 10, 0, 0);
    final windowStart = DateTime.utc(2026, 9, 1, 0, 0, 0);
    final windowEnd = DateTime.utc(2026, 9, 7, 23, 59, 59);
    final milestone = DateTime.utc(2026, 9, 15, 0, 0, 0);

    final validBudget = StudyTimeBudget(
      learnerId: 'learner_100',
      dailyAvailableMinutes: 60,
      preferredSessionDurationMinutes: 20,
      maxSessionsPerDay: 3,
      effectiveFrom: fixedTime,
    );

    test('1. Valid construction with target milestone', () {
      final request = StudyPlanRequest(
        learnerId: 'learner_100',
        planningWindowStart: windowStart,
        planningWindowEnd: windowEnd,
        targetMilestoneDate: milestone,
        timeBudget: validBudget,
        scopedObjectiveIds: ['lo_1', 'lo_2'],
        requestedAt: fixedTime,
      );

      expect(request.learnerId, equals('learner_100'));
      expect(request.planningWindowStart, equals(windowStart));
      expect(request.planningWindowEnd, equals(windowEnd));
      expect(request.targetMilestoneDate, equals(milestone));
      expect(request.hasMilestoneTarget, isTrue);
      expect(request.windowDays, equals(7));
      expect(request.scopedObjectiveIds, equals(['lo_1', 'lo_2']));
    });

    test('2. Rejects empty learnerId', () {
      expect(
        () => StudyPlanRequest(
          learnerId: '   ',
          planningWindowStart: windowStart,
          planningWindowEnd: windowEnd,
          timeBudget: validBudget,
          requestedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('3. Rejects reversed planning window (end before start)', () {
      expect(
        () => StudyPlanRequest(
          learnerId: 'learner_100',
          planningWindowStart: windowEnd,
          planningWindowEnd: windowStart,
          timeBudget: validBudget,
          requestedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('4. Rejects targetMilestoneDate before planningWindowStart', () {
      expect(
        () => StudyPlanRequest(
          learnerId: 'learner_100',
          planningWindowStart: windowStart,
          planningWindowEnd: windowEnd,
          targetMilestoneDate: DateTime.utc(2026, 8, 30, 0, 0, 0),
          timeBudget: validBudget,
          requestedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('5. JSON serialization and deserialization roundtrip', () {
      final request = StudyPlanRequest(
        learnerId: 'learner_100',
        planningWindowStart: windowStart,
        planningWindowEnd: windowEnd,
        targetMilestoneDate: milestone,
        timeBudget: validBudget,
        scopedObjectiveIds: ['lo_1'],
        requestedAt: fixedTime,
        metadata: {'source': 'manual_plan'},
      );

      final json = request.toJson();
      final restored = StudyPlanRequest.fromJson(json);

      expect(restored, equals(request));
      expect(restored.hashCode, equals(request.hashCode));
      expect(restored.metadata['source'], equals('manual_plan'));
    });
  });
}
