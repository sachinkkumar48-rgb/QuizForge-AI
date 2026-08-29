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
  group('P24 Study Planner End-to-End Integration Tests (TITAN-KO-024.0)', () {
    const plannerService = DeterministicStudyPlannerService();
    final fixedTime = DateTime.utc(2026, 8, 27, 12, 0, 0);
    final planStart = DateTime.utc(2026, 9, 1);
    final planEnd = DateTime.utc(2026, 9, 5); // 5-day planning window

    test(
        'Full multi-tier integration across P17, P18, P20, P21, P23 to P24 StudyPlan',
        () {
      // 1. P17 Curriculum Objectives
      final lo1 = LearningObjective(
        id: 'lo_const_01',
        unitId: 'unit_const',
        title: 'Preamble and Basic Structure',
        description: 'Doctrinal fundamentals of Indian Constitution',
        bloomLevel: BloomTaxonomyLevel.understand,
        provenance: 'test_p17',
      );
      final lo2 = LearningObjective(
        id: 'lo_const_02',
        unitId: 'unit_const',
        title: 'Fundamental Rights (Articles 14-18)',
        description: 'Right to Equality jurisprudence',
        bloomLevel: BloomTaxonomyLevel.apply,
        provenance: 'test_p17',
      );
      final lo3 = LearningObjective(
        id: 'lo_const_03',
        unitId: 'unit_const',
        title: 'Fundamental Freedoms (Article 19)',
        description: 'Six freedoms and reasonable restrictions',
        bloomLevel: BloomTaxonomyLevel.analyze,
        provenance: 'test_p17',
      );
      final lo4 = LearningObjective(
        id: 'lo_const_04',
        unitId: 'unit_const',
        title: 'Right to Life and Personal Liberty (Article 21)',
        description: 'Due process, privacy, and expansive rights',
        bloomLevel: BloomTaxonomyLevel.evaluate,
        provenance: 'test_p17',
      );
      final lo5 = LearningObjective(
        id: 'lo_const_05',
        unitId: 'unit_const',
        title: 'Constitutional Remedies (Article 32)',
        description: 'Prerogative writs and PIL jurisdiction',
        bloomLevel: BloomTaxonomyLevel.apply,
        provenance: 'test_p17',
      );
      final allObjectives = [lo1, lo2, lo3, lo4, lo5];

      // 2. P18 Learner Progress: lo1 is achieved, lo2 is inProgress, others notStarted
      final progressList = [
        LearnerProgress(
          learnerId: 'learner_aspirant_01',
          objectiveId: 'lo_const_01',
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt: DateTime.utc(2026, 8, 20),
        ),
        LearnerProgress(
          learnerId: 'learner_aspirant_01',
          objectiveId: 'lo_const_02',
          attemptCount: 8,
          correctCount: 3,
          status: LearnerObjectiveStatus.inProgress,
          lastAttemptAt: DateTime.utc(2026, 8, 26),
        ),
      ];

      // 3. P20 Spaced Repetition Review Schedule:
      // lo1 was achieved earlier and has an overdue review (due on Aug 25)
      final reviewSchedule = ReviewSchedule(
        learnerId: 'learner_aspirant_01',
        items: {
          'lo_const_01': ReviewItem(
            objectiveId: 'lo_const_01',
            intervalDays: 5,
            easeFactor: 2.5,
            nextReviewDate:
                DateTime.utc(2026, 8, 25), // overdue relative to 2026-09-01
            reviewCount: 1,
          ),
        },
        createdAt: fixedTime,
      );

      // 4. P23 Weak-Spot Diagnostics:
      // lo2 exhibits observed weakness (accuracy 37.5%, 8 attempts >= 5 evidence threshold)
      final weakSpotProfile = WeakSpotProfile(
        learnerId: 'learner_aspirant_01',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        evaluatedAt: fixedTime,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_const_02',
            attemptCount: 8,
            correctCount: 3,
            observedAccuracy: 0.375,
            deficiencyScore: 0.625,
          ),
        ],
      );

      // 5. P21 Adaptive Recommendation Queue:
      // Top recommendation for lo3 (curriculumAdvance)
      final recommendationQueue = RecommendationQueue(
        learnerId: 'learner_aspirant_01',
        generatedAt: fixedTime,
        policyUsed: const RecommendationPolicy(),
        items: [
          LearningRecommendation(
            recommendationId: 'rec_adv_01',
            learnerId: 'learner_aspirant_01',
            objectiveId: 'lo_const_03',
            type: RecommendationType.curriculumAdvance,
            priorityScore: 0.88,
            rationale:
                'Top curriculum advance recommendation unblocking unit progression',
            suggestedConfig: SessionConfiguration(
              learnerId: 'learner_aspirant_01',
              objectiveIds: const ['lo_const_03'],
            ),
          ),
        ],
      );

      // 6. P24 Study Plan Request:
      // 5-day window, 40 min/day, 20 min session (2 sessions per day)
      final budget = StudyTimeBudget(
        learnerId: 'learner_aspirant_01',
        dailyAvailableMinutes: 40,
        preferredSessionDurationMinutes: 20,
        maxSessionsPerDay: 2,
        effectiveFrom: fixedTime,
      );

      final planRequest = StudyPlanRequest(
        learnerId: 'learner_aspirant_01',
        planningWindowStart: planStart,
        planningWindowEnd: planEnd,
        timeBudget: budget,
        requestedAt: fixedTime,
      );

      // 7. Generate Study Plan via P24 Engine
      final plan = plannerService.generatePlan(
        request: planRequest,
        reviewSchedule: reviewSchedule,
        weakSpotProfile: weakSpotProfile,
        recommendationQueue: recommendationQueue,
        availableObjectives: allObjectives,
        progressList: progressList,
        generatedAt: fixedTime,
      );

      // 8. Assertions:
      expect(plan.learnerId, equals('learner_aspirant_01'));
      expect(plan.totalDays, equals(5));

      // Day 1:
      // Slot 1: Tier 1 Overdue review for lo_const_01
      // Slot 2: Tier 3 Weak-spot practice for lo_const_02
      final day1 = plan.dailyAgendas[0];
      expect(day1.items, hasLength(2));
      expect(day1.items[0].allocationType,
          equals(StudyAllocationType.overdueReview));
      expect(day1.items[0].objectiveId, equals('lo_const_01'));
      expect(day1.items[0].priorityRank, equals(1));
      expect(day1.items[0].explanation, contains('Overdue spaced review'));

      expect(day1.items[1].allocationType,
          equals(StudyAllocationType.weakSpotPractice));
      expect(day1.items[1].objectiveId, equals('lo_const_02'));
      expect(day1.items[1].priorityRank, equals(2));
      expect(day1.items[1].explanation, contains('Weak-spot practice'));

      // Day 2:
      // Slot 1: Tier 4 P21 recommended action for lo_const_03
      // Slot 2: Tier 5 New curriculum for lo_const_04
      final day2 = plan.dailyAgendas[1];
      expect(day2.items, hasLength(2));
      expect(day2.items[0].allocationType,
          equals(StudyAllocationType.recommendedAction));
      expect(day2.items[0].objectiveId, equals('lo_const_03'));

      expect(day2.items[1].allocationType,
          equals(StudyAllocationType.newCurriculum));
      expect(day2.items[1].objectiveId, equals('lo_const_04'));

      // Day 3:
      // Slot 1: Tier 5 New curriculum for lo_const_05
      final day3 = plan.dailyAgendas[2];
      expect(day3.items, hasLength(1));
      expect(day3.items[0].allocationType,
          equals(StudyAllocationType.newCurriculum));
      expect(day3.items[0].objectiveId, equals('lo_const_05'));

      // Total scheduled objectives across plan
      expect(
          plan.allScheduledObjectiveIds,
          containsAll([
            'lo_const_01',
            'lo_const_02',
            'lo_const_03',
            'lo_const_04',
            'lo_const_05',
          ]));

      // Verify that achieved lo_const_01 was NOT scheduled as new curriculum
      final newCurriculumItems = <String>[];
      for (final day in plan.dailyAgendas) {
        for (final item in day.items) {
          if (item.allocationType == StudyAllocationType.newCurriculum) {
            newCurriculumItems.add(item.objectiveId);
          }
        }
      }
      expect(newCurriculumItems, isNot(contains('lo_const_01')));
      expect(newCurriculumItems, isNot(contains('lo_const_02')));

      // Verify zero upstream mutation
      expect(reviewSchedule.items['lo_const_01']?.intervalDays, equals(5));
      expect(weakSpotProfile.identifiedWeakSpotsCount, equals(1));
      expect(recommendationQueue.items, hasLength(1));
      expect(progressList[0].status, equals(LearnerObjectiveStatus.achieved));
    });
  });
}
