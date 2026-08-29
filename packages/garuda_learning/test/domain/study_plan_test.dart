import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/daily_study_agenda.dart';
import 'package:garuda_learning/domain/entities/study_agenda_item.dart';
import 'package:garuda_learning/domain/entities/study_allocation_type.dart';
import 'package:garuda_learning/domain/entities/study_plan.dart';
import 'package:garuda_learning/domain/entities/study_plan_request.dart';
import 'package:garuda_learning/domain/entities/study_time_budget.dart';

void main() {
  group('StudyPlan Entity Tests (TITAN-KO-024.0 P24)', () {
    final fixedTime = DateTime.utc(2026, 8, 27, 10, 0, 0);
    final day1 = DateTime.utc(2026, 9, 1);
    final day2 = DateTime.utc(2026, 9, 2);

    final budget = StudyTimeBudget(
      learnerId: 'learner_100',
      dailyAvailableMinutes: 60,
      preferredSessionDurationMinutes: 20,
      maxSessionsPerDay: 3,
      effectiveFrom: fixedTime,
    );

    final request = StudyPlanRequest(
      learnerId: 'learner_100',
      planningWindowStart: day1,
      planningWindowEnd: day2,
      timeBudget: budget,
      requestedAt: fixedTime,
    );

    final itemDay1 = StudyAgendaItem(
      itemId: 'item_1',
      objectiveId: 'lo_1',
      allocationType: StudyAllocationType.dueReview,
      scheduledDate: day1,
      allocatedMinutes: 20,
      priorityRank: 1,
      explanation: 'Scheduled due review',
    );

    final itemDay2 = StudyAgendaItem(
      itemId: 'item_2',
      objectiveId: 'lo_2',
      allocationType: StudyAllocationType.newCurriculum,
      scheduledDate: day2,
      allocatedMinutes: 20,
      priorityRank: 1,
      explanation: 'Scheduled new curriculum',
    );

    final agenda1 = DailyStudyAgenda(
      learnerId: 'learner_100',
      date: day1,
      items: [itemDay1],
      availableMinutes: 60,
    );

    final agenda2 = DailyStudyAgenda(
      learnerId: 'learner_100',
      date: day2,
      items: [itemDay2],
      availableMinutes: 60,
    );

    test('1. Valid construction sorts daily agendas chronologically', () {
      final plan = StudyPlan(
        planId: 'plan_001',
        request: request,
        dailyAgendas: [agenda2, agenda1], // pass reverse order
        generatedAt: fixedTime,
      );

      expect(plan.planId, equals('plan_001'));
      expect(plan.learnerId, equals('learner_100'));
      expect(plan.totalDays, equals(2));
      expect(plan.dailyAgendas.first.date, equals(day1));
      expect(plan.dailyAgendas.last.date, equals(day2));
      expect(plan.totalAllocatedMinutes, equals(40));
      expect(plan.totalAllocatedSessions, equals(2));
      expect(plan.hasMilestoneWarning, isFalse);
      expect(plan.allScheduledObjectiveIds, equals({'lo_1', 'lo_2'}));
      expect(plan.isObjectiveScheduled('lo_1'), isTrue);
      expect(plan.isObjectiveScheduled('lo_3'), isFalse);
    });

    test('2. Rejects empty planId or negative unallocatedObjectivesCount', () {
      expect(
        () => StudyPlan(
          planId: '  ',
          request: request,
          dailyAgendas: [agenda1],
          generatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => StudyPlan(
          planId: 'plan_001',
          request: request,
          dailyAgendas: [agenda1],
          unallocatedObjectivesCount: -1,
          generatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('3. agendaForDate retrieves matching daily agenda by calendar date',
        () {
      final plan = StudyPlan(
        planId: 'plan_001',
        request: request,
        dailyAgendas: [agenda1, agenda2],
        generatedAt: fixedTime,
      );

      final found = plan.agendaForDate(DateTime.utc(2026, 9, 1, 15, 30));
      expect(found, isNotNull);
      expect(found?.date, equals(day1));

      final notFound = plan.agendaForDate(DateTime.utc(2026, 9, 10));
      expect(notFound, isNull);
    });

    test('4. JSON serialization and deserialization roundtrip', () {
      final plan = StudyPlan(
        planId: 'plan_001',
        request: request,
        dailyAgendas: [agenda1, agenda2],
        unallocatedObjectivesCount: 3,
        milestoneWarning: 'Capacity alert: 3 unallocated items remain',
        generatedAt: fixedTime,
        metadata: {'version': 'v1'},
      );

      final json = plan.toJson();
      final restored = StudyPlan.fromJson(json);

      expect(restored, equals(plan));
      expect(restored.hashCode, equals(plan.hashCode));
      expect(restored.unallocatedObjectivesCount, equals(3));
      expect(restored.hasMilestoneWarning, isTrue);
      expect(restored.milestoneWarning, contains('Capacity alert'));
      expect(restored.metadata['version'], equals('v1'));
    });
  });
}
