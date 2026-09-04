import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P41 Adaptive Decision Policy Tests', () {
    test('standard policy has correct defaults and priority hierarchy', () {
      final policy = AdaptiveDecisionPolicy.standard;

      expect(policy.remediationMinAttempts, equals(3));
      expect(policy.remediationSuccessRateThreshold, equals(0.50));
      expect(policy.masteryMinAttempts, equals(5));
      expect(policy.masterySuccessRateThreshold, equals(0.80));
      expect(policy.reviewIntervalDays, equals(3));
      expect(
        policy.priorityOrder,
        equals([
          LearningDecisionType.continuation,
          LearningDecisionType.remediation,
          LearningDecisionType.review,
          LearningDecisionType.reinforcement,
          LearningDecisionType.advancement,
          LearningDecisionType.complete,
        ]),
      );
    });

    test('policy constructor validates bounds', () {
      expect(
        () => AdaptiveDecisionPolicy(remediationMinAttempts: 0),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveDecisionPolicy(remediationSuccessRateThreshold: 1.5),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveDecisionPolicy(masteryMinAttempts: 0),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveDecisionPolicy(masterySuccessRateThreshold: -0.1),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveDecisionPolicy(reviewIntervalDays: 0),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveDecisionPolicy(priorityOrder: []),
        throwsArgumentError,
      );
    });

    test('policy serializes and deserializes cleanly via JSON', () {
      final policy = AdaptiveDecisionPolicy(
        remediationMinAttempts: 4,
        remediationSuccessRateThreshold: 0.40,
        masteryMinAttempts: 6,
        masterySuccessRateThreshold: 0.85,
        reviewIntervalDays: 5,
        priorityOrder: [
          LearningDecisionType.remediation,
          LearningDecisionType.continuation,
          LearningDecisionType.complete,
        ],
      );

      final json = policy.toJson();
      final roundtrip = AdaptiveDecisionPolicy.fromJson(json);

      expect(roundtrip.remediationMinAttempts, equals(4));
      expect(roundtrip.remediationSuccessRateThreshold, equals(0.40));
      expect(roundtrip.masteryMinAttempts, equals(6));
      expect(roundtrip.masterySuccessRateThreshold, equals(0.85));
      expect(roundtrip.reviewIntervalDays, equals(5));
      expect(roundtrip.priorityOrder.length, equals(3));
      expect(roundtrip.priorityOrder.first,
          equals(LearningDecisionType.remediation));
    });
  });

  group('P41 Learning Target & Evidence Domain Tests', () {
    test('LearningTarget factories instantiate correct types', () {
      final cursorTarget = LearningTarget.sessionCursor(
        sessionId: 'sess_1',
        cursorIndex: 3,
        objectiveId: 'lo_const_01',
      );
      expect(cursorTarget.targetType, equals(LearningTargetType.sessionCursor));
      expect(cursorTarget.cursorIndex, equals(3));
      expect(cursorTarget.objectiveId, equals('lo_const_01'));

      final lessonTarget = LearningTarget.remedialLesson(
        lessonId: 'rem_01',
        objectiveId: 'lo_const_02',
        topic: 'Constitutional Law',
      );
      expect(
          lessonTarget.targetType, equals(LearningTargetType.remedialLesson));
      expect(lessonTarget.remedialLessonId, equals('rem_01'));
      expect(lessonTarget.topic, equals('Constitutional Law'));

      final objTarget = LearningTarget.objective(
        objectiveId: 'lo_const_03',
        type: LearningTargetType.practiceObjective,
      );
      expect(
          objTarget.targetType, equals(LearningTargetType.practiceObjective));
      expect(objTarget.objectiveId, equals('lo_const_03'));

      expect(LearningTarget.none.targetType, equals(LearningTargetType.none));
    });

    test('LearningTarget serialization round-trip', () {
      final target = LearningTarget.sessionCursor(
        sessionId: 'sess_99',
        cursorIndex: 2,
        objectiveId: 'lo_01',
        topic: 'Fundamental Rights',
      );

      final json = target.toJson();
      final roundtrip = LearningTarget.fromJson(json);

      expect(roundtrip.targetId, equals(target.targetId));
      expect(roundtrip.targetType, equals(LearningTargetType.sessionCursor));
      expect(roundtrip.cursorIndex, equals(2));
      expect(roundtrip.objectiveId, equals('lo_01'));
      expect(roundtrip.topic, equals('Fundamental Rights'));
    });

    test('LearningDecisionEvidence bounds and JSON serialization', () {
      expect(
        () => LearningDecisionEvidence(
          authoritativeStateRevision: 0,
        ),
        throwsArgumentError,
      );

      final evidence = LearningDecisionEvidence(
        objectiveId: 'lo_fr_01',
        topic: 'Constitution',
        subject: 'Law',
        masteryScore: 0.75,
        attemptCount: 10,
        correctCount: 7,
        successRate: 0.70,
        confidence: 0.90,
        authoritativeStateRevision: 4,
        checkpointRevision: 2,
        activeSessionId: 'sess_123',
        hasUnfinishedSession: true,
        notes: ['Rule matched'],
      );

      final json = evidence.toJson();
      final roundtrip = LearningDecisionEvidence.fromJson(json);

      expect(roundtrip.objectiveId, equals('lo_fr_01'));
      expect(roundtrip.masteryScore, equals(0.75));
      expect(roundtrip.attemptCount, equals(10));
      expect(roundtrip.correctCount, equals(7));
      expect(roundtrip.authoritativeStateRevision, equals(4));
      expect(roundtrip.checkpointRevision, equals(2));
      expect(roundtrip.activeSessionId, equals('sess_123'));
      expect(roundtrip.hasUnfinishedSession, isTrue);
      expect(roundtrip.notes, equals(['Rule matched']));
    });
  });

  group('P41 Decision Freshness & Revision Safety Tests', () {
    final now = DateTime.utc(2026, 9, 4, 12, 0, 0);

    test('isStale correctly identifies when state revision has advanced', () {
      final stateAtRev3 = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 3,
      );

      final decision = AdaptiveLearningDecision(
        decisionId: 'dec_1',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.reinforcement,
        priority: LearningDecisionPriority.medium,
        reason: 'Practice in progress',
        target: LearningTarget.objective(
          objectiveId: 'lo_01',
          type: LearningTargetType.practiceObjective,
        ),
        evidence: LearningDecisionEvidence(authoritativeStateRevision: 3),
        authoritativeStateRevision: 3,
        decidedAt: now,
      );

      // Same revision: not stale
      expect(decision.isStale(stateAtRev3), isFalse);

      // Advanced state: stale!
      final stateAtRev4 = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 4,
      );
      expect(decision.isStale(stateAtRev4), isTrue);

      // Tenant mismatch in isStale throws ArgumentError
      final foreignState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_2',
        examId: 'upsc',
        createdAt: now,
        revision: 3,
      );
      expect(() => decision.isStale(foreignState), throwsArgumentError);
    });

    test(
        'AdaptiveLearningDecision serializes and deserializes cleanly via JSON',
        () {
      final decision = AdaptiveLearningDecision(
        decisionId: 'dec_test_1',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.remediation,
        priority: LearningDecisionPriority.urgent,
        reason: 'Low accuracy on LO1',
        target: LearningTarget.objective(
          objectiveId: 'lo_1',
          type: LearningTargetType.remedialLesson,
        ),
        evidence: LearningDecisionEvidence(
          objectiveId: 'lo_1',
          authoritativeStateRevision: 2,
        ),
        authoritativeStateRevision: 2,
        decidedAt: now,
      );

      final json = decision.toJson();
      final roundtrip = AdaptiveLearningDecision.fromJson(json);

      expect(roundtrip.decisionId, equals('dec_test_1'));
      expect(roundtrip.learnerId, equals('learner_1'));
      expect(roundtrip.examId, equals('upsc'));
      expect(roundtrip.type, equals(LearningDecisionType.remediation));
      expect(roundtrip.priority, equals(LearningDecisionPriority.urgent));
      expect(roundtrip.authoritativeStateRevision, equals(2));
      expect(roundtrip.target.objectiveId, equals('lo_1'));
    });
  });

  group('P41 Learning Continuation Plan Downstream Handoff Tests', () {
    final now = DateTime.utc(2026, 9, 4, 12, 0, 0);

    test('plan generates tailored P33 and P34 configs for each decision type',
        () {
      final types = [
        LearningDecisionType.continuation,
        LearningDecisionType.remediation,
        LearningDecisionType.review,
        LearningDecisionType.reinforcement,
        LearningDecisionType.advancement,
        LearningDecisionType.complete,
      ];

      for (final type in types) {
        final decision = AdaptiveLearningDecision(
          decisionId: 'dec_${type.name}',
          learnerId: 'learner_1',
          examId: 'upsc',
          type: type,
          priority: LearningDecisionPriority.medium,
          reason: 'Test reason for ${type.name}',
          target: LearningTarget.objective(
            objectiveId: 'lo_sample',
            type: LearningTargetType.practiceObjective,
            topic: 'Sample Topic',
            subject: 'Law',
          ),
          evidence: LearningDecisionEvidence(authoritativeStateRevision: 1),
          authoritativeStateRevision: 1,
          decidedAt: now,
        );

        final plan = LearningContinuationPlan(
          planId: 'plan_${type.name}',
          decision: decision,
          createdAt: now,
        );

        final p33Config = plan.toAdaptiveQuestionSelectionConfig();
        expect(p33Config.examId, equals('upsc'));
        if (type != LearningDecisionType.complete) {
          expect(p33Config.targetQuestionCount, equals(5));
          expect(p33Config.scopedObjectiveIds, equals(['lo_sample']));
        } else {
          expect(p33Config.targetQuestionCount, equals(1));
        }

        final p34Config = plan.toAdaptivePracticeSessionConfig();
        expect(p34Config.examId, equals('upsc'));
        expect(p34Config.learnerId, equals('learner_1'));

        switch (type) {
          case LearningDecisionType.continuation:
            expect(p34Config.sessionMode, equals(PracticeSessionMode.standard));
            break;
          case LearningDecisionType.remediation:
            expect(p34Config.sessionMode,
                equals(PracticeSessionMode.remedialPractice));
            break;
          case LearningDecisionType.review:
            expect(p34Config.sessionMode,
                equals(PracticeSessionMode.mixedRevision));
            break;
          case LearningDecisionType.reinforcement:
            expect(p34Config.sessionMode,
                equals(PracticeSessionMode.weaknessFocused));
            break;
          case LearningDecisionType.advancement:
          case LearningDecisionType.complete:
            expect(p34Config.sessionMode, equals(PracticeSessionMode.standard));
            break;
        }
      }
    });

    test('plan serialization round-trip', () {
      final decision = AdaptiveLearningDecision(
        decisionId: 'dec_plan_test',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.remediation,
        priority: LearningDecisionPriority.urgent,
        reason: 'Remediation needed',
        target: LearningTarget.remedialLesson(
          lessonId: 'rem_101',
          objectiveId: 'lo_const_01',
        ),
        evidence: LearningDecisionEvidence(authoritativeStateRevision: 1),
        authoritativeStateRevision: 1,
        decidedAt: now,
      );

      final plan = LearningContinuationPlan(
        planId: 'plan_test_01',
        decision: decision,
        createdAt: now,
        metadata: {'testKey': 'testVal'},
      );

      final json = plan.toJson();
      final roundtrip = LearningContinuationPlan.fromJson(json);

      expect(roundtrip.planId, equals('plan_test_01'));
      expect(roundtrip.decision.decisionId, equals('dec_plan_test'));
      expect(roundtrip.target.remedialLessonId, equals('rem_101'));
      expect(roundtrip.metadata['testKey'], equals('testVal'));
    });
  });

  group('P41 Adaptive Learning Decision Engine Evaluation Tests', () {
    final now = DateTime.utc(2026, 9, 4, 12, 0, 0);
    final engine = AdaptiveLearningDecisionEngine();

    test('multi-tenant isolation: throws on tenant mismatch', () {
      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_A',
        examId: 'upsc',
        createdAt: now,
      );

      final mismatchedCheckpoint = SessionCheckpoint(
        sessionId: 'sess_1',
        learnerId: 'learner_B', // Mismatch!
        examId: 'upsc',
        questionIndex: 2,
        completedQuestionIds: const ['q1', 'q2'],
        activeObjectiveId: 'lo_1',
        timestamp: now,
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
      );

      expect(
        () => engine.evaluate(
          authoritativeState: state,
          activeCheckpoint: mismatchedCheckpoint,
        ),
        throwsArgumentError,
      );
    });

    test(
        'Rule 1 (Continuation): unfinished checkpoint triggers continuation decision',
        () {
      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
      );

      final checkpoint = SessionCheckpoint(
        sessionId: 'sess_active_1',
        learnerId: 'learner_1',
        examId: 'upsc',
        questionIndex: 3,
        completedQuestionIds: const ['q1', 'q2', 'q3'],
        activeObjectiveId: 'lo_const_01',
        timestamp: now,
        checkpointRevision: 3,
        authoritativeStateRevision: 1,
        isCompleted: false,
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        activeCheckpoint: checkpoint,
      );

      expect(decision.type, equals(LearningDecisionType.continuation));
      expect(decision.priority, equals(LearningDecisionPriority.urgent));
      expect(
          decision.target.targetType, equals(LearningTargetType.sessionCursor));
      expect(decision.target.cursorIndex, equals(3));
      expect(decision.target.objectiveId, equals('lo_const_01'));
      expect(decision.evidence.hasUnfinishedSession, isTrue);
      expect(decision.evidence.activeSessionId, equals('sess_active_1'));
      expect(decision.evidence.checkpointRevision, equals(3));

      // Trace step verification
      expect(decision.trace, isNotNull);
      final step = decision.trace!.steps.first;
      expect(step.policy, equals(LearningDecisionType.continuation));
      expect(step.isMatched, isTrue);
    });

    test('Completed checkpoint does not trigger continuation', () {
      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
      );

      final checkpoint = SessionCheckpoint(
        sessionId: 'sess_done',
        learnerId: 'learner_1',
        examId: 'upsc',
        questionIndex: 5,
        completedQuestionIds: const ['q1', 'q2', 'q3', 'q4', 'q5'],
        activeObjectiveId: 'lo_const_01',
        timestamp: now,
        checkpointRevision: 5,
        authoritativeStateRevision: 1,
        isCompleted: true, // Completed!
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        activeCheckpoint: checkpoint,
      );

      expect(decision.type, isNot(equals(LearningDecisionType.continuation)));
    });

    test(
        'Rule 2 (Remediation): material weakness triggers remediation decision and binds lesson',
        () {
      final progressMap = {
        'lo_weak': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_weak',
          attemptCount: 4,
          correctCount: 1, // 25% success rate (< 50%)
          status: LearnerObjectiveStatus.inProgress,
          lastAttemptAt: now,
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      final lesson = RemedialLesson(
        lessonId: 'rem_lo_weak_v1',
        objectiveId: 'lo_weak',
        title: 'Remedial Lesson on Weak Objective',
        summary: 'Conceptual overview',
        learningPoints: const ['Point 1', 'Point 2'],
        explanation: 'Detailed explanation',
        examples: const ['Example 1'],
        misconceptions: const ['Common trap'],
        sourceReferences: const [],
        contentOrigin: ContentOrigin.pedagogicalExplanation,
        estimatedMinutes: 15,
        bloomLevel: BloomTaxonomyLevel.understand,
        authoredAt: now,
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        availableRemedialLessons: [lesson],
      );

      expect(decision.type, equals(LearningDecisionType.remediation));
      expect(decision.priority, equals(LearningDecisionPriority.urgent));
      expect(decision.target.targetType,
          equals(LearningTargetType.remedialLesson));
      expect(decision.target.remedialLessonId, equals('rem_lo_weak_v1'));
      expect(decision.target.objectiveId, equals('lo_weak'));
      expect(decision.evidence.attemptCount, equals(4));
      expect(decision.evidence.correctCount, equals(1));
      expect(decision.evidence.successRate, equals(0.25));

      // Test plan formulation automatically attaches remedial lesson
      final plan = engine.formulateContinuationPlan(
        decision: decision,
        remedialLesson: lesson,
      );
      expect(plan.remedialLesson?.lessonId, equals('rem_lo_weak_v1'));
    });

    test(
        'Rule 3 (Review): mastered objective due for review triggers review decision',
        () {
      final progressMap = {
        'lo_mastered': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_mastered',
          attemptCount: 10,
          correctCount: 9, // 90% success rate
          status: LearnerObjectiveStatus.achieved,
          achievedAt: now.subtract(const Duration(days: 10)),
          lastAttemptAt:
              now.subtract(const Duration(days: 5)), // 5 days ago (> 3 days)
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        asOfDate: now,
      );

      expect(decision.type, equals(LearningDecisionType.review));
      expect(decision.priority, equals(LearningDecisionPriority.high));
      expect(decision.target.targetType,
          equals(LearningTargetType.reviewObjective));
      expect(decision.target.objectiveId, equals('lo_mastered'));
      expect(decision.evidence.daysSinceReview, equals(5));
    });

    test(
        'Rule 3 (Review): explicit ReviewItem that is due triggers review decision',
        () {
      final progressMap = {
        'lo_rev_item': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_rev_item',
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt: now.subtract(const Duration(days: 2)),
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      final reviewItem = ReviewItem(
        objectiveId: 'lo_rev_item',
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate:
            now.subtract(const Duration(hours: 4)), // overdue by 4 hours
        lastReviewed: now.subtract(const Duration(days: 1)),
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        reviewItems: [reviewItem],
        asOfDate: now,
      );

      expect(decision.type, equals(LearningDecisionType.review));
      expect(decision.target.objectiveId, equals('lo_rev_item'));
    });

    test(
        'Rule 4 (Reinforcement): in-progress objective triggers reinforcement decision',
        () {
      final progressMap = {
        'lo_in_progress': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_in_progress',
          attemptCount: 2,
          correctCount:
              1, // 50% success (< 80% mastery, but not enough attempts for remediation)
          status: LearnerObjectiveStatus.inProgress,
          lastAttemptAt: now,
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        asOfDate: now,
      );

      expect(decision.type, equals(LearningDecisionType.reinforcement));
      expect(decision.priority, equals(LearningDecisionPriority.medium));
      expect(decision.target.targetType,
          equals(LearningTargetType.practiceObjective));
      expect(decision.target.objectiveId, equals('lo_in_progress'));
      expect(decision.evidence.attemptCount, equals(2));
    });

    test(
        'Rule 5 (Advancement): advances to next objective with satisfied prerequisites',
        () {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final firstObjId = framework.allObjectives[0].id;
      final secondObjId = framework.allObjectives[1].id;

      // First objective achieved, second unattempted
      final progressMap = {
        firstObjId: LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: firstObjId,
          attemptCount: 6,
          correctCount: 5,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt:
              now, // recently practiced (< 3 days ago, so not due for review)
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        framework: framework,
        asOfDate: now,
      );

      expect(decision.type, equals(LearningDecisionType.advancement));
      expect(decision.priority, equals(LearningDecisionPriority.low));
      expect(decision.target.targetType,
          equals(LearningTargetType.curriculumObjective));
      expect(decision.target.objectiveId, equals(secondObjId));
    });

    test(
        'Rule 6 (Complete): all objectives achieved and no reviews pending marks complete',
        () {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final progressMap = <String, LearnerProgress>{};

      for (final obj in framework.allObjectives) {
        progressMap[obj.id] = LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: obj.id,
          attemptCount: 10,
          correctCount: 10,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt: now, // recent, no review due
        );
      }

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        framework: framework,
        asOfDate: now,
      );

      expect(decision.type, equals(LearningDecisionType.complete));
      expect(decision.priority, equals(LearningDecisionPriority.none));
      expect(decision.target.targetType, equals(LearningTargetType.none));
    });

    test(
        'Priority conflict resolution: continuation beats remediation, review, reinforcement',
        () {
      // Create a state where remediation is needed AND review is due AND in-progress exists
      final progressMap = {
        'lo_weak': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_weak',
          attemptCount: 4,
          correctCount: 1, // Needs remediation
          status: LearnerObjectiveStatus.inProgress,
          lastAttemptAt: now,
        ),
        'lo_rev': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_rev',
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt:
              now.subtract(const Duration(days: 10)), // Due for review
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      // BUT an active unfinished session checkpoint is also present
      final checkpoint = SessionCheckpoint(
        sessionId: 'sess_interrupted',
        learnerId: 'learner_1',
        examId: 'upsc',
        questionIndex: 1,
        completedQuestionIds: const ['q1'],
        activeObjectiveId: 'lo_rev',
        timestamp: now,
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        isCompleted: false,
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        activeCheckpoint: checkpoint,
        asOfDate: now,
      );

      // Continuation must win highest priority!
      expect(decision.type, equals(LearningDecisionType.continuation));

      // Without the checkpoint, remediation must beat review
      final decisionWithoutCheckpoint = engine.evaluate(
        authoritativeState: state,
        asOfDate: now,
      );
      expect(decisionWithoutCheckpoint.type,
          equals(LearningDecisionType.remediation));
    });

    test('Custom policy override changes priority order deterministically', () {
      final progressMap = {
        'lo_weak': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_weak',
          attemptCount: 4,
          correctCount: 1,
          status: LearnerObjectiveStatus.inProgress,
          lastAttemptAt: now,
        ),
        'lo_rev': LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'lo_rev',
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt: now.subtract(const Duration(days: 10)),
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: progressMap,
        lastUpdatedAt: now,
      );

      // Policy where REVIEW takes precedence over REMEDIATION
      final reviewFirstPolicy = AdaptiveDecisionPolicy(
        priorityOrder: [
          LearningDecisionType.continuation,
          LearningDecisionType.review,
          LearningDecisionType.remediation,
          LearningDecisionType.reinforcement,
          LearningDecisionType.advancement,
          LearningDecisionType.complete,
        ],
      );

      final decision = engine.evaluate(
        authoritativeState: state,
        overridePolicy: reviewFirstPolicy,
        asOfDate: now,
      );

      expect(decision.type, equals(LearningDecisionType.review));
      expect(decision.target.objectiveId, equals('lo_rev'));
    });
  });
}
