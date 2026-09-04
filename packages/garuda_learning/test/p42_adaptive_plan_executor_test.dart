/// P42 Adaptive Learning Plan Executor Unit Tests (TITAN-KO-042.0 P42).
///
/// Tests domain contracts, validation rules, deterministic activity routing,
/// staleness protection, multi-tenant isolation, and audit trail generation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final now = DateTime.utc(2026, 9, 15, 12, 0, 0);

  NormalizedQuestion buildQuestion({
    required String id,
    String examId = 'upsc',
    String objectiveId = 'lo_const_01',
  }) {
    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: 2024,
      paper: 'GS1',
      subject: 'Polity',
      topic: 'Constitution',
      normalizedText: 'Question text for $id',
      originalText: 'Original question text for $id',
      options: const [
        Option(key: 'A', text: 'Option A', isCorrect: true),
        Option(key: 'B', text: 'Option B', isCorrect: false),
        Option(key: 'C', text: 'Option C', isCorrect: false),
        Option(key: 'D', text: 'Option D', isCorrect: false),
      ],
      officialAnswer: const Answer(
        correctOptionKeys: ['A'],
        officialAnswerSource: 'Official Key',
      ),
      explanation: 'Explanation for $id',
      difficulty: 'Medium',
      source: PyqSourceReference.official(
        examId: examId,
        year: 2024,
        paper: 'GS1',
      ),
      objectiveIds: [objectiveId],
    );
  }

  LearningContinuationPlan buildPlan({
    required String planId,
    String learnerId = 'learner_1',
    String examId = 'upsc',
    required LearningDecisionType type,
    required LearningTarget target,
    int authoritativeRevision = 2,
    RemedialLesson? remedialLesson,
  }) {
    final decision = AdaptiveLearningDecision(
      decisionId: 'dec_$planId',
      learnerId: learnerId,
      examId: examId,
      type: type,
      priority: LearningDecisionPriority.medium,
      reason: 'Reason for $planId',
      target: target,
      evidence: LearningDecisionEvidence(
        objectiveId: target.objectiveId,
        authoritativeStateRevision: authoritativeRevision,
      ),
      authoritativeStateRevision: authoritativeRevision,
      decidedAt: now,
    );

    return LearningContinuationPlan(
      planId: planId,
      decision: decision,
      target: target,
      remedialLesson: remedialLesson,
      createdAt: now,
    );
  }

  group('P42 Domain Models & Serialization Tests', () {
    test('LearningActivityExecutionStatus properties and display names', () {
      expect(LearningActivityExecutionStatus.success.isSuccess, isTrue);
      expect(LearningActivityExecutionStatus.resumed.isSuccess, isTrue);
      expect(LearningActivityExecutionStatus.completed.isSuccess, isTrue);
      expect(LearningActivityExecutionStatus.completed.isTerminal, isTrue);

      expect(LearningActivityExecutionStatus.stalePlan.isFailure, isTrue);
      expect(LearningActivityExecutionStatus.invalidPlan.isFailure, isTrue);
      expect(LearningActivityExecutionStatus.invalidTarget.isFailure, isTrue);
      expect(LearningActivityExecutionStatus.executionFailed.isFailure, isTrue);

      expect(LearningActivityExecutionStatus.success.displayName,
          equals('Activity Started'));
      expect(LearningActivityExecutionStatus.resumed.displayName,
          equals('Session Resumed'));
      expect(LearningActivityExecutionStatus.completed.displayName,
          equals('Curriculum Completed'));
    });

    test('PlanExecutionError and Exception models', () {
      final error = PlanExecutionError(
        code: PlanExecutionErrorCode.stalePlan,
        message: 'Plan is stale',
        details: {'rev': 3},
      );
      expect(error.code, equals(PlanExecutionErrorCode.stalePlan));
      expect(error.message, equals('Plan is stale'));
      expect(error.details['rev'], equals(3));

      final json = error.toJson();
      final roundtrip = PlanExecutionError.fromJson(json);
      expect(roundtrip.code, equals(error.code));
      expect(roundtrip.message, equals(error.message));
      expect(roundtrip.details, equals(error.details));

      const ex = PlanExecutionException(
        code: PlanExecutionErrorCode.tenantMismatch,
        message: 'Tenant mismatch',
      );
      final exError = ex.toError();
      expect(exError.code, equals(PlanExecutionErrorCode.tenantMismatch));
    });

    test('ExecutionAuditStep and ExecutionAuditTrail models & serialization',
        () {
      final step = ExecutionAuditStep(
        stepIndex: 1,
        stepName: 'PLAN_RECEIVED',
        timestamp: now,
        isSuccess: true,
        message: 'Step 1 success',
        details: {'key': 'val'},
      );

      final stepJson = step.toJson();
      final roundtripStep = ExecutionAuditStep.fromJson(stepJson);
      expect(roundtripStep.stepIndex, equals(1));
      expect(roundtripStep.stepName, equals('PLAN_RECEIVED'));
      expect(roundtripStep.isSuccess, isTrue);
      expect(roundtripStep.message, equals('Step 1 success'));

      final trail = ExecutionAuditTrail(
        traceId: 'trc_1',
        learnerId: 'learner_1',
        examId: 'upsc',
        steps: [step],
        startedAt: now,
        completedAt: now.add(const Duration(milliseconds: 15)),
      );

      expect(trail.durationMs, equals(15));
      expect(trail.allStepsSuccessful, isTrue);

      final trailJson = trail.toJson();
      final roundtripTrail = ExecutionAuditTrail.fromJson(trailJson);
      expect(roundtripTrail.traceId, equals('trc_1'));
      expect(roundtripTrail.learnerId, equals('learner_1'));
      expect(roundtripTrail.steps.length, equals(1));
    });

    test('LearningActivityExecutionRequest validation and serialization', () {
      final plan = buildPlan(
        planId: 'plan_req_test',
        type: LearningDecisionType.advancement,
        target: LearningTarget.objective(
          objectiveId: 'lo_const_01',
          type: LearningTargetType.curriculumObjective,
        ),
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 2,
      );

      expect(
        () => LearningActivityExecutionRequest(
          requestId: '',
          learnerId: 'learner_1',
          examId: 'upsc',
          plan: plan,
          currentState: state,
          requestedAt: now,
        ),
        throwsArgumentError,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_1',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        requestedAt: now,
      );

      final json = request.toJson();
      final roundtrip = LearningActivityExecutionRequest.fromJson(json);
      expect(roundtrip.requestId, equals('req_1'));
      expect(roundtrip.learnerId, equals('learner_1'));
      expect(roundtrip.plan.planId, equals(plan.planId));
    });

    test('LearningActivityExecutionResult serialization round-trip', () {
      final auditTrail = ExecutionAuditTrail(
        traceId: 'trc_res',
        learnerId: 'learner_1',
        examId: 'upsc',
        steps: [
          ExecutionAuditStep(
            stepIndex: 1,
            stepName: 'PLAN_RECEIVED',
            timestamp: now,
            message: 'Received',
          ),
        ],
        startedAt: now,
        completedAt: now,
      );

      final result = LearningActivityExecutionResult.completed(
        requestId: 'req_res',
        learnerId: 'learner_1',
        examId: 'upsc',
        planId: 'plan_1',
        decisionId: 'dec_1',
        target: LearningTarget.none,
        sourceRevision: 3,
        executionRevision: 3,
        auditTrail: auditTrail,
        executedAt: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isCompleted, isTrue);
      expect(result.hasSession, isFalse);

      final json = result.toJson();
      final roundtrip = LearningActivityExecutionResult.fromJson(json);
      expect(roundtrip.requestId, equals('req_res'));
      expect(
          roundtrip.status, equals(LearningActivityExecutionStatus.completed));
      expect(roundtrip.sourceRevision, equals(3));
      expect(roundtrip.executionRevision, equals(3));
    });
  });

  group('P42 Safety & Precondition Validation Tests', () {
    const executor = AdaptiveLearningPlanExecutor();

    test('rejects cross-learner execution with tenantMismatch', () async {
      final plan = buildPlan(
        planId: 'plan_tenant_mismatch',
        learnerId: 'learner_A',
        examId: 'upsc',
        type: LearningDecisionType.advancement,
        target: LearningTarget.objective(
          objectiveId: 'lo_01',
          type: LearningTargetType.curriculumObjective,
        ),
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_B', // Mismatch!
        examId: 'upsc',
        createdAt: now,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_tm',
        learnerId: 'learner_B',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(
          result.status, equals(LearningActivityExecutionStatus.invalidPlan));
      expect(result.error?.code, equals(PlanExecutionErrorCode.tenantMismatch));
      expect(
          result.auditTrail.steps
              .any((s) => s.stepName == 'TENANT_VALIDATED' && !s.isSuccess),
          isTrue);
    });

    test('rejects cross-exam execution with tenantMismatch', () async {
      final plan = buildPlan(
        planId: 'plan_exam_mismatch',
        learnerId: 'learner_1',
        examId: 'bpsc',
        type: LearningDecisionType.advancement,
        target: LearningTarget.objective(
          objectiveId: 'lo_01',
          type: LearningTargetType.curriculumObjective,
        ),
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc', // Mismatch!
        createdAt: now,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_em',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(
          result.status, equals(LearningActivityExecutionStatus.invalidPlan));
      expect(result.error?.code, equals(PlanExecutionErrorCode.tenantMismatch));
    });

    test('rejects stale plan when state revision has advanced', () async {
      final plan = buildPlan(
        planId: 'plan_stale',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.reinforcement,
        target: LearningTarget.objective(
          objectiveId: 'lo_01',
          type: LearningTargetType.practiceObjective,
        ),
        authoritativeRevision: 2, // Formulated against rev 2
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 4, // Current state is at rev 4!
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_stale',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.stalePlan));
      expect(result.error?.code, equals(PlanExecutionErrorCode.stalePlan));
      expect(
          result.auditTrail.steps
              .any((s) => s.stepName == 'REVISION_VALIDATED' && !s.isSuccess),
          isTrue);
    });

    test('rejects future revision plan when state revision is behind plan',
        () async {
      final plan = buildPlan(
        planId: 'plan_future',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.reinforcement,
        target: LearningTarget.objective(
          objectiveId: 'lo_01',
          type: LearningTargetType.practiceObjective,
        ),
        authoritativeRevision: 5, // Future revision 5
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 2, // State is only at rev 2
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_future',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(
          result.status, equals(LearningActivityExecutionStatus.invalidPlan));
      expect(result.error?.code, equals(PlanExecutionErrorCode.invalidPlan));
    });

    test(
        'rejects new practice activity when an active session is already uncompleted',
        () async {
      final plan = buildPlan(
        planId: 'plan_conflict',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.remediation,
        target: LearningTarget.objective(
          objectiveId: 'lo_weak',
          type: LearningTargetType.remedialLesson,
        ),
        authoritativeRevision: 2,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 2,
      );

      final activeCheckpoint = SessionCheckpoint(
        sessionId: 'sess_already_active',
        learnerId: 'learner_1',
        examId: 'upsc',
        questionIndex: 2,
        completedQuestionIds: const ['q1', 'q2'],
        activeObjectiveId: 'lo_prev',
        timestamp: now,
        checkpointRevision: 2,
        authoritativeStateRevision: 2,
        isCompleted: false, // Active and unfinished!
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_conflict',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        activeCheckpoint: activeCheckpoint,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status,
          equals(LearningActivityExecutionStatus.sessionAlreadyActive));
      expect(result.error?.code,
          equals(PlanExecutionErrorCode.sessionAlreadyActive));
      expect(
          result.auditTrail.steps
              .any((s) => s.stepName == 'CONFLICT_CHECKED' && !s.isSuccess),
          isTrue);
    });

    test('rejects execution when target objective ID is empty', () async {
      final plan = buildPlan(
        planId: 'plan_bad_target',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.advancement,
        target: LearningTarget.none, // Missing objectiveId!
        authoritativeRevision: 1,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 1,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_bad_target',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(
          result.status, equals(LearningActivityExecutionStatus.invalidTarget));
      expect(result.error?.code, equals(PlanExecutionErrorCode.invalidTarget));
    });

    test('rejects new session execution when corpus is empty', () async {
      final plan = buildPlan(
        planId: 'plan_no_corpus',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.advancement,
        target: LearningTarget.objective(
          objectiveId: 'lo_01',
          type: LearningTargetType.curriculumObjective,
        ),
        authoritativeRevision: 1,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 1,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_no_corpus',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        corpus: const [], // Empty corpus!
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status,
          equals(LearningActivityExecutionStatus.executionFailed));
      expect(result.error?.code, equals(PlanExecutionErrorCode.corpusEmpty));
    });
  });

  group('P42 Deterministic Activity Routing Tests', () {
    const executor = AdaptiveLearningPlanExecutor();

    test(
        'COMPLETE activity produces terminal result without starting a session',
        () async {
      final plan = buildPlan(
        planId: 'plan_complete',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.complete,
        target: LearningTarget.none,
        authoritativeRevision: 5,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 5,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_complete',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.completed));
      expect(result.isSuccess, isTrue);
      expect(result.isCompleted, isTrue);
      expect(result.hasSession, isFalse);
      expect(
          result.auditTrail.steps.any((s) => s.stepName == 'ACTIVITY_ROUTED'),
          isTrue);
      expect(
          result.auditTrail.steps
              .any((s) => s.stepName == 'DOWNSTREAM_EXECUTION_COMPLETED'),
          isTrue);
    });

    test('REMEDIATION activity routes to remedial practice and binds lesson',
        () async {
      const objId = 'lo_weak_fr';
      final questions = List.generate(
        5,
        (i) => buildQuestion(id: 'q_rem_$i', objectiveId: objId),
      );

      final lesson = RemedialLesson(
        lessonId: 'rem_lesson_01',
        objectiveId: objId,
        title: 'Fundamental Rights Micro-Lesson',
        summary: 'Reviewing key concepts',
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

      final plan = buildPlan(
        planId: 'plan_remediation',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.remediation,
        target: LearningTarget.remedialLesson(
          lessonId: 'rem_lesson_01',
          objectiveId: objId,
        ),
        authoritativeRevision: 2,
        remedialLesson: lesson,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 2,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_remed',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        corpus: questions,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.hasSession, isTrue);
      expect(result.remedialLesson?.lessonId, equals('rem_lesson_01'));
      expect(result.sessionSpec?.config.sessionMode,
          equals(PracticeSessionMode.remedialPractice));
      expect(result.executionState?.status,
          equals(PracticeExecutionStatus.inProgress));
    });

    test('REVIEW activity routes to mixed revision practice session', () async {
      const objId = 'lo_rev_01';
      final questions = List.generate(
        5,
        (i) => buildQuestion(id: 'q_rev_$i', objectiveId: objId),
      );

      final plan = buildPlan(
        planId: 'plan_review',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.review,
        target: LearningTarget.objective(
          objectiveId: objId,
          type: LearningTargetType.reviewObjective,
        ),
        authoritativeRevision: 3,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 3,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_rev',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        corpus: questions,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.success));
      expect(result.hasSession, isTrue);
      expect(result.sessionSpec?.config.sessionMode,
          equals(PracticeSessionMode.mixedRevision));
    });

    test('REINFORCEMENT activity routes to weakness-focused practice session',
        () async {
      const objId = 'lo_reinf_01';
      final questions = List.generate(
        5,
        (i) => buildQuestion(id: 'q_reinf_$i', objectiveId: objId),
      );

      final plan = buildPlan(
        planId: 'plan_reinf',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.reinforcement,
        target: LearningTarget.objective(
          objectiveId: objId,
          type: LearningTargetType.practiceObjective,
        ),
        authoritativeRevision: 1,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 1,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_reinf',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        corpus: questions,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.success));
      expect(result.sessionSpec?.config.sessionMode,
          equals(PracticeSessionMode.weaknessFocused));
    });

    test('ADVANCEMENT activity routes to standard practice session', () async {
      const objId = 'lo_adv_01';
      final questions = List.generate(
        5,
        (i) => buildQuestion(id: 'q_adv_$i', objectiveId: objId),
      );

      final plan = buildPlan(
        planId: 'plan_adv',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.advancement,
        target: LearningTarget.objective(
          objectiveId: objId,
          type: LearningTargetType.curriculumObjective,
        ),
        authoritativeRevision: 1,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 1,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_adv',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        corpus: questions,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.success));
      expect(result.sessionSpec?.config.sessionMode,
          equals(PracticeSessionMode.standard));
    });

    test('CONTINUATION activity resumes session at exact checkpoint cursor',
        () async {
      const objId = 'lo_cont_01';
      final questions = List.generate(
        5,
        (i) => buildQuestion(id: 'q_cont_$i', objectiveId: objId),
      );

      const orchestrator = AdaptivePracticeSessionOrchestrator();
      final selection = AdaptiveQuestionSelectionResult(
        examId: 'upsc',
        selectedQuestions: questions,
        selectedCandidates: questions
            .map((q) => AdaptiveQuestionCandidate(
                  question: q,
                  historicalPriority: 0.5,
                  learnerWeakness: 0.5,
                  exposureCount: 0,
                  recencyScore: 1.0,
                  difficultyFit: 0.8,
                  sourceQualityScore: 1.0,
                  selectionScore: 0.8,
                  isEligible: true,
                  scoreBreakdown: const {},
                ))
            .toList(),
        allCandidates: const [],
        requestedCount: 5,
        eligibleCount: 5,
        config: AdaptiveQuestionSelectionConfig(examId: 'upsc'),
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: AdaptivePracticeSessionConfig(
          examId: 'upsc',
          learnerId: 'learner_1',
        ),
        orchestratedAt: now,
      );

      final checkpoint = SessionCheckpoint(
        sessionId: spec.sessionId,
        learnerId: 'learner_1',
        examId: 'upsc',
        questionIndex: 3, // Paused at Q3!
        completedQuestionIds: ['q_cont_0', 'q_cont_1', 'q_cont_2'],
        activeObjectiveId: objId,
        timestamp: now,
        checkpointRevision: 3,
        authoritativeStateRevision: 2,
        isCompleted: false,
      );

      final plan = buildPlan(
        planId: 'plan_cont',
        learnerId: 'learner_1',
        examId: 'upsc',
        type: LearningDecisionType.continuation,
        target: LearningTarget.sessionCursor(
          sessionId: spec.sessionId,
          cursorIndex: 3,
          objectiveId: objId,
        ),
        authoritativeRevision: 2,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: now,
        revision: 2,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_cont',
        learnerId: 'learner_1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        existingSessionSpec: spec,
        activeCheckpoint: checkpoint,
        requestedAt: now,
      );

      final result = await executor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.resumed));
      expect(result.isSuccess, isTrue);
      expect(result.isResumed, isTrue);
      expect(result.executionState?.currentQuestionIndex, equals(3));
      expect(result.checkpoint?.questionIndex, equals(3));
      expect(result.checkpoint?.completedQuestionIds,
          equals(['q_cont_0', 'q_cont_1', 'q_cont_2']));
    });
  });
}
