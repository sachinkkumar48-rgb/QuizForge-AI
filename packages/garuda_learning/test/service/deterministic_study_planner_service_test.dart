import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learner_progress.dart';
import 'package:garuda_learning/domain/entities/learning_objective.dart';
import 'package:garuda_learning/domain/entities/learning_recommendation.dart';
import 'package:garuda_learning/domain/entities/recommendation_policy.dart';
import 'package:garuda_learning/domain/entities/recommendation_queue.dart';
import 'package:garuda_learning/domain/entities/recommendation_type.dart';
import 'package:garuda_learning/domain/entities/review_item.dart';
import 'package:garuda_learning/domain/entities/review_schedule.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';
import 'package:garuda_learning/domain/entities/study_allocation_type.dart';
import 'package:garuda_learning/domain/entities/study_plan_request.dart';
import 'package:garuda_learning/domain/entities/study_time_budget.dart';
import 'package:garuda_learning/domain/entities/weak_spot_profile.dart';
import 'package:garuda_learning/service/deterministic_study_planner_service.dart';

void main() {
  group('DeterministicStudyPlannerService Tests (TITAN-KO-024.0 P24 Stage 2)',
      () {
    const service = DeterministicStudyPlannerService();
    final fixedRequestedAt = DateTime.utc(2026, 8, 27, 9, 0, 0);
    final windowStart = DateTime.utc(2026, 9, 1);
    final windowEnd = DateTime.utc(2026, 9, 3); // 3-day window

    final standardBudget = StudyTimeBudget(
      learnerId: 'learner_001',
      dailyAvailableMinutes: 60,
      preferredSessionDurationMinutes: 20,
      maxSessionsPerDay: 3, // 3 sessions * 20m = 60m
      effectiveFrom: fixedRequestedAt,
    );

    LearningObjective makeObjective(String id,
        {String unitId = 'unit_1', String title = ''}) {
      return LearningObjective(
        id: id,
        unitId: unitId,
        title: title.isNotEmpty ? title : 'Title for $id',
        description: 'Description for $id',
        bloomLevel: BloomTaxonomyLevel.understand,
        provenance: 'test_p17',
      );
    }

    test(
        '1. Cold-start learner schedules new curriculum in unit and objective sequence',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowEnd,
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      final objectives = [
        makeObjective('lo_b', unitId: 'unit_1'),
        makeObjective('lo_a', unitId: 'unit_1'),
        makeObjective('lo_c', unitId: 'unit_2'),
      ];

      final plan = service.generatePlan(
        request: request,
        availableObjectives: objectives,
      );

      expect(plan.totalDays, equals(3));
      expect(plan.dailyAgendas.first.items, hasLength(3));
      // First day schedules lo_a, lo_b, lo_c
      final day1Items = plan.dailyAgendas.first.items;
      expect(day1Items[0].objectiveId, equals('lo_a'));
      expect(day1Items[1].objectiveId, equals('lo_b'));
      expect(day1Items[2].objectiveId, equals('lo_c'));
      expect(day1Items[0].allocationType,
          equals(StudyAllocationType.newCurriculum));
      expect(day1Items[0].allocatedMinutes, equals(20));
      expect(plan.dailyAgendas.first.allocatedMinutes, equals(60));
      expect(plan.dailyAgendas.first.isFull, isTrue);
    });

    test(
        '2. Strict daily capacity enforcement: cannot exceed available minutes or max sessions',
        () {
      final tightBudget = StudyTimeBudget(
        learnerId: 'learner_001',
        dailyAvailableMinutes: 35,
        preferredSessionDurationMinutes: 15,
        maxSessionsPerDay: 2, // 2 sessions * 15m = 30m, which fits in 35m
        effectiveFrom: fixedRequestedAt,
      );

      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowStart, // 1 day
        timeBudget: tightBudget,
        requestedAt: fixedRequestedAt,
      );

      final objectives = List.generate(10, (i) => makeObjective('lo_$i'));

      final plan = service.generatePlan(
        request: request,
        availableObjectives: objectives,
      );

      expect(plan.dailyAgendas, hasLength(1));
      final dayAgenda = plan.dailyAgendas.first;
      expect(dayAgenda.sessionCount, equals(2));
      expect(dayAgenda.allocatedMinutes, equals(30));
      expect(dayAgenda.remainingCapacityMinutes, equals(5));
      expect(dayAgenda.isFull, isFalse);
    });

    test(
        '3. Overdue reviews are balanced across days rather than overloading Day 1',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowEnd, // 3 days, each day can take 3 sessions
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      // 4 overdue reviews scheduled before windowStart (2026-09-01)
      final reviewItems = {
        'lo_overdue_1': ReviewItem(
          objectiveId: 'lo_overdue_1',
          intervalDays: 5,
          easeFactor: 2.5,
          nextReviewDate: DateTime.utc(2026, 8, 20),
        ),
        'lo_overdue_2': ReviewItem(
          objectiveId: 'lo_overdue_2',
          intervalDays: 3,
          easeFactor: 2.5,
          nextReviewDate: DateTime.utc(2026, 8, 21),
        ),
        'lo_overdue_3': ReviewItem(
          objectiveId: 'lo_overdue_3',
          intervalDays: 2,
          easeFactor: 2.5,
          nextReviewDate: DateTime.utc(2026, 8, 22),
        ),
        'lo_overdue_4': ReviewItem(
          objectiveId: 'lo_overdue_4',
          intervalDays: 1,
          easeFactor: 2.5,
          nextReviewDate: DateTime.utc(2026, 8, 23),
        ),
      };

      final schedule = ReviewSchedule(
        learnerId: 'learner_001',
        items: reviewItems,
        createdAt: fixedRequestedAt,
      );

      final objectives = [
        makeObjective('lo_curr_1'),
        makeObjective('lo_curr_2')
      ];

      // Default maxOverdueReviewsFractionPerDay is 0.50.
      // For 3 max sessions: floor(3 * 0.50) = 1 overdue review balanced per day.
      final plan = service.generatePlan(
        request: request,
        reviewSchedule: schedule,
        availableObjectives: objectives,
      );

      // On Day 1: 1 overdue review + new curriculum (not all 3 sessions consumed by overdues)
      final day1 = plan.dailyAgendas[0];
      final day1Overdue = day1.itemsForType(StudyAllocationType.overdueReview);
      expect(day1Overdue, hasLength(1));
      expect(day1Overdue.first.objectiveId, equals('lo_overdue_1'));

      // Day 2 also receives balanced overdue review
      final day2 = plan.dailyAgendas[1];
      final day2Overdue = day2.itemsForType(StudyAllocationType.overdueReview);
      expect(day2Overdue, hasLength(1));
      expect(day2Overdue.first.objectiveId, equals('lo_overdue_2'));
    });

    test('4. Due reviews scheduled on Day 2 are allocated on Day 2', () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart, // 2026-09-01
        planningWindowEnd: windowEnd, // 2026-09-03
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      final day2Date = DateTime.utc(2026, 9, 2, 8, 0, 0);
      final schedule = ReviewSchedule(
        learnerId: 'learner_001',
        items: {
          'lo_due_day2': ReviewItem(
            objectiveId: 'lo_due_day2',
            intervalDays: 4,
            easeFactor: 2.5,
            nextReviewDate: day2Date,
          ),
        },
        createdAt: fixedRequestedAt,
      );

      final plan = service.generatePlan(
        request: request,
        reviewSchedule: schedule,
      );

      // Day 1 has no due review
      expect(plan.dailyAgendas[0].containsObjective('lo_due_day2'), isFalse);
      // Day 2 has the due review
      expect(plan.dailyAgendas[1].containsObjective('lo_due_day2'), isTrue);
      final item = plan.dailyAgendas[1].itemForObjective('lo_due_day2');
      expect(item?.allocationType, equals(StudyAllocationType.dueReview));
    });

    test(
        '5. 5-Tier priority hierarchy: Overdue > Due > Weak Spot > Rec > New Curriculum',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowStart, // 1 day, 5 sessions budget
        timeBudget: StudyTimeBudget(
          learnerId: 'learner_001',
          dailyAvailableMinutes: 100,
          preferredSessionDurationMinutes: 20,
          maxSessionsPerDay: 5,
          effectiveFrom: fixedRequestedAt,
        ),
        requestedAt: fixedRequestedAt,
      );

      final schedule = ReviewSchedule(
        learnerId: 'learner_001',
        items: {
          'lo_overdue': ReviewItem(
            objectiveId: 'lo_overdue',
            intervalDays: 1,
            easeFactor: 2.5,
            nextReviewDate: DateTime.utc(2026, 8, 25), // overdue
          ),
          'lo_due': ReviewItem(
            objectiveId: 'lo_due',
            intervalDays: 1,
            easeFactor: 2.5,
            nextReviewDate: DateTime.utc(2026, 9, 1, 10, 0, 0), // due today
          ),
        },
        createdAt: fixedRequestedAt,
      );

      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_001',
        totalEvaluatedObjectives: 5,
        evaluatedWithSufficientEvidence: 5,
        evaluatedAt: fixedRequestedAt,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_weak',
            attemptCount: 6,
            correctCount: 2,
            deficiencyScore: 0.67,
          ),
        ],
      );

      final recQueue = RecommendationQueue(
        learnerId: 'learner_001',
        generatedAt: fixedRequestedAt,
        policyUsed: const RecommendationPolicy(),
        items: [
          LearningRecommendation(
            recommendationId: 'rec_1',
            learnerId: 'learner_001',
            objectiveId: 'lo_rec',
            type: RecommendationType.curriculumAdvance,
            priorityScore: 0.85,
            rationale: 'Top curriculum advance recommendation',
            suggestedConfig: SessionConfiguration(
              learnerId: 'learner_001',
              objectiveIds: const ['lo_rec'],
            ),
          ),
        ],
      );

      final curriculum = [makeObjective('lo_new')];

      final plan = service.generatePlan(
        request: request,
        reviewSchedule: schedule,
        weakSpotProfile: weakProfile,
        recommendationQueue: recQueue,
        availableObjectives: curriculum,
      );

      final items = plan.dailyAgendas.first.items;
      expect(items, hasLength(5));
      expect(
          items[0].allocationType, equals(StudyAllocationType.overdueReview));
      expect(items[0].objectiveId, equals('lo_overdue'));
      expect(items[1].allocationType, equals(StudyAllocationType.dueReview));
      expect(items[1].objectiveId, equals('lo_due'));
      expect(items[2].allocationType,
          equals(StudyAllocationType.weakSpotPractice));
      expect(items[2].objectiveId, equals('lo_weak'));
      expect(items[3].allocationType,
          equals(StudyAllocationType.recommendedAction));
      expect(items[3].objectiveId, equals('lo_rec'));
      expect(
          items[4].allocationType, equals(StudyAllocationType.newCurriculum));
      expect(items[4].objectiveId, equals('lo_new'));
    });

    test('6. Scoped objective IDs restricts candidates to scoped set', () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowStart,
        timeBudget: standardBudget,
        scopedObjectiveIds: ['lo_allowed_1', 'lo_allowed_2'],
        requestedAt: fixedRequestedAt,
      );

      final objectives = [
        makeObjective('lo_allowed_1'),
        makeObjective('lo_ignored_1'),
        makeObjective('lo_allowed_2'),
      ];

      final plan = service.generatePlan(
        request: request,
        availableObjectives: objectives,
      );

      final scheduledIds = plan.allScheduledObjectiveIds;
      expect(scheduledIds, contains('lo_allowed_1'));
      expect(scheduledIds, contains('lo_allowed_2'));
      expect(scheduledIds, isNot(contains('lo_ignored_1')));
    });

    test(
        '7. Target milestone produces advisory warning if items remain unallocated',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowStart, // 1 day, max 1 session
        targetMilestoneDate: DateTime.utc(2026, 9, 10),
        timeBudget: StudyTimeBudget(
          learnerId: 'learner_001',
          dailyAvailableMinutes: 20,
          preferredSessionDurationMinutes: 20,
          maxSessionsPerDay: 1,
          effectiveFrom: fixedRequestedAt,
        ),
        requestedAt: fixedRequestedAt,
      );

      final objectives = [
        makeObjective('lo_1'),
        makeObjective('lo_2'),
        makeObjective('lo_3'),
      ];

      final plan = service.generatePlan(
        request: request,
        availableObjectives: objectives,
      );

      expect(plan.dailyAgendas.first.sessionCount, equals(1));
      expect(plan.unallocatedObjectivesCount, equals(2));
      expect(plan.hasMilestoneWarning, isTrue);
      expect(plan.milestoneWarning, contains('Milestone capacity advisory'));
      expect(plan.milestoneWarning, contains('2 candidate study item(s)'));
    });

    test(
        '8. Deterministic replay: identical inputs yield identical plan bit-for-bit',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowEnd,
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      final objectives = [
        makeObjective('lo_1'),
        makeObjective('lo_2'),
        makeObjective('lo_3'),
      ];

      final planA = service.generatePlan(
        request: request,
        availableObjectives: objectives,
        generatedAt: fixedRequestedAt,
      );

      final planB = service.generatePlan(
        request: request,
        availableObjectives: objectives,
        generatedAt: fixedRequestedAt,
      );

      expect(planA, equals(planB));
      expect(planA.hashCode, equals(planB.hashCode));
      expect(planA.toJson(), equals(planB.toJson()));
    });

    test('9. Zero upstream mutation: inputs remain completely untouched', () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowEnd,
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      final reviewItem = ReviewItem(
        objectiveId: 'lo_rev',
        intervalDays: 3,
        easeFactor: 2.5,
        nextReviewDate: DateTime.utc(2026, 8, 20),
        reviewCount: 2,
      );

      final schedule = ReviewSchedule(
        learnerId: 'learner_001',
        items: {'lo_rev': reviewItem},
        createdAt: fixedRequestedAt,
      );

      service.generatePlan(
        request: request,
        reviewSchedule: schedule,
      );

      // Verify schedule and review item state
      final itemAfter = schedule.getItem('lo_rev');
      expect(itemAfter?.intervalDays, equals(3));
      expect(itemAfter?.easeFactor, equals(2.5));
      expect(itemAfter?.reviewCount, equals(2));
      expect(itemAfter?.nextReviewDate, equals(DateTime.utc(2026, 8, 20)));
    });

    test(
        '10. Explainability: all scheduled items provide factual scheduling rationales',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowStart,
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      final objectives = [
        makeObjective('lo_sample', title: 'Fundamental Rights')
      ];
      final plan = service.generatePlan(
        request: request,
        availableObjectives: objectives,
      );

      final item = plan.dailyAgendas.first.items.first;
      expect(item.explanation, contains('Fundamental Rights'));
      expect(item.explanation, contains('understand'));
      expect(item.explanation, isNot(contains('smart')));
      expect(item.explanation, isNot(contains('bad')));
      expect(item.explanation, isNot(contains('guarantee')));
    });

    test('11. 7-Day planning window generates 7 continuous daily agendas', () {
      final weekStart = DateTime.utc(2026, 9, 1);
      final weekEnd = DateTime.utc(2026, 9, 7);
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: weekStart,
        planningWindowEnd: weekEnd,
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      final objectives = List.generate(25, (i) => makeObjective('lo_$i'));
      final plan = service.generatePlan(
        request: request,
        availableObjectives: objectives,
      );

      expect(plan.totalDays, equals(7));
      expect(plan.dailyAgendas, hasLength(7));
      for (var i = 0; i < 7; i++) {
        expect(plan.dailyAgendas[i].date,
            equals(weekStart.add(Duration(days: i))));
        expect(plan.dailyAgendas[i].sessionCount,
            equals(3)); // 3 sessions/day * 20m = 60m
      }
      expect(plan.totalAllocatedSessions, equals(21));
      expect(plan.totalAllocatedMinutes, equals(420));
    });

    test(
        '12. Learner progress isolation: other learner progress does not block target learner curriculum',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_target',
        planningWindowStart: windowStart,
        planningWindowEnd: windowStart, // 1 day
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      final objectives = [makeObjective('lo_shared')];

      // Progress belongs to a DIFFERENT learner
      final otherLearnerProgress = [
        LearnerProgress(
          learnerId: 'learner_other',
          objectiveId: 'lo_shared',
          attemptCount: 10,
          correctCount: 10,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt: fixedRequestedAt,
        ),
      ];

      final plan = service.generatePlan(
        request: request,
        availableObjectives: objectives,
        progressList: otherLearnerProgress,
      );

      // Since other learner's progress was for learner_other, lo_shared is STILL new curriculum for learner_target
      expect(plan.dailyAgendas.first.containsObjective('lo_shared'), isTrue);
      expect(
        plan.dailyAgendas.first.itemForObjective('lo_shared')?.allocationType,
        equals(StudyAllocationType.newCurriculum),
      );
    });

    test(
        '13. Cross-tier objective deduplication: multi-tier candidate is scheduled only once at highest priority tier',
        () {
      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowEnd, // 3 days, 3 sessions each
        timeBudget: standardBudget,
        requestedAt: fixedRequestedAt,
      );

      // Objective 'lo_contested' is simultaneously:
      // 1. Overdue review (Tier 1)
      // 2. Weak-spot practice (Tier 3)
      // 3. Recommendation (Tier 4)
      final schedule = ReviewSchedule(
        learnerId: 'learner_001',
        items: {
          'lo_contested': ReviewItem(
            objectiveId: 'lo_contested',
            intervalDays: 1,
            easeFactor: 2.5,
            nextReviewDate: DateTime.utc(2026, 8, 20), // overdue
          ),
        },
        createdAt: fixedRequestedAt,
      );

      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_001',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedRequestedAt,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_contested',
            attemptCount: 6,
            correctCount: 1,
            deficiencyScore: 0.83,
          ),
        ],
      );

      final recQueue = RecommendationQueue(
        learnerId: 'learner_001',
        generatedAt: fixedRequestedAt,
        policyUsed: const RecommendationPolicy(),
        items: [
          LearningRecommendation(
            recommendationId: 'rec_contested',
            learnerId: 'learner_001',
            objectiveId: 'lo_contested',
            type: RecommendationType.weakDomainRemediation,
            priorityScore: 0.95,
            rationale: 'Remediation recommendation',
            suggestedConfig: SessionConfiguration(
              learnerId: 'learner_001',
              objectiveIds: const ['lo_contested'],
            ),
          ),
        ],
      );

      final plan = service.generatePlan(
        request: request,
        reviewSchedule: schedule,
        weakSpotProfile: weakProfile,
        recommendationQueue: recQueue,
      );

      // Verify that 'lo_contested' appears EXACTLY ONCE across the entire multi-day plan
      final allItems = plan.dailyAgendas
          .expand((d) => d.items)
          .where((i) => i.objectiveId == 'lo_contested')
          .toList();
      expect(allItems, hasLength(1));

      // Verify it was scheduled under Tier 1 (Overdue Review), NOT downgraded or duplicated
      expect(allItems.first.allocationType,
          equals(StudyAllocationType.overdueReview));
      expect(plan.allScheduledObjectiveIds, contains('lo_contested'));
    });

    test(
        '14. Single-session capacity boundary: 1 session/day permits 1 overdue review without exceeding budget',
        () {
      final singleSessionBudget = StudyTimeBudget(
        learnerId: 'learner_001',
        dailyAvailableMinutes: 30,
        preferredSessionDurationMinutes: 30,
        maxSessionsPerDay: 1,
        effectiveFrom: fixedRequestedAt,
      );

      final request = StudyPlanRequest(
        learnerId: 'learner_001',
        planningWindowStart: windowStart,
        planningWindowEnd: windowStart, // 1 day
        timeBudget: singleSessionBudget,
        requestedAt: fixedRequestedAt,
      );

      final schedule = ReviewSchedule(
        learnerId: 'learner_001',
        items: {
          'lo_overdue_only': ReviewItem(
            objectiveId: 'lo_overdue_only',
            intervalDays: 1,
            easeFactor: 2.5,
            nextReviewDate: DateTime.utc(2026, 8, 20),
          ),
        },
        createdAt: fixedRequestedAt,
      );

      final plan = service.generatePlan(
        request: request,
        reviewSchedule: schedule,
      );

      expect(plan.dailyAgendas.first.sessionCount, equals(1));
      expect(plan.dailyAgendas.first.allocatedMinutes, equals(30));
      expect(plan.dailyAgendas.first.remainingCapacityMinutes, equals(0));
      expect(plan.dailyAgendas.first.isFull, isTrue);
      expect(plan.dailyAgendas.first.items.first.objectiveId,
          equals('lo_overdue_only'));
    });
  });
}
