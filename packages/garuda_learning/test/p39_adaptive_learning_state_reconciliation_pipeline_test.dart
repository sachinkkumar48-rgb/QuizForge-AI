/// P39 Adaptive Learning State Reconciliation & Persistence Pipeline Unit Tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);

  const proposer = LearningStateUpdateProposer();
  const consolidator = PracticeOutcomeConsolidator();
  const engine = AdaptivePracticeExecutionEngine();
  const orchestrator = AdaptivePracticeSessionOrchestrator();

  late InMemoryAuthoritativeLearningStateRepository repository;
  late AuthoritativeLearningStateRecoveryService recoveryService;
  late AdaptiveLearningStateReconciler reconciler;
  late AdaptiveLearningStateReconciliationPipeline pipeline;

  NormalizedQuestion buildQuestion({
    required String id,
    String examId = 'upsc',
    int year = 2024,
    String paper = 'GS1',
    String subject = 'Polity',
    String topic = 'Fundamental Rights',
    List<String>? objectiveIds,
    String difficulty = 'Medium',
  }) {
    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: year,
      paper: paper,
      subject: subject,
      topic: topic,
      normalizedText: 'Normalized question text for $id',
      originalText: 'Normalized question text for $id',
      options: const [
        Option(key: 'A', text: 'Option A', isCorrect: true),
        Option(key: 'B', text: 'Option B', isCorrect: false),
        Option(key: 'C', text: 'Option C', isCorrect: false),
        Option(key: 'D', text: 'Option D', isCorrect: false),
      ],
      officialAnswer: const Answer(
        correctOptionKeys: ['A'],
        officialAnswerSource: 'Official Commission Key',
      ),
      explanation: 'Explanation for $id',
      difficulty: difficulty,
      source: PyqSourceReference.official(
        examId: examId,
        year: year,
        paper: paper,
      ),
      objectiveIds: objectiveIds ?? const ['obj_polity_fr'],
    );
  }

  AdaptiveQuestionCandidate buildCandidate({
    required NormalizedQuestion question,
  }) {
    return AdaptiveQuestionCandidate(
      question: question,
      historicalPriority: 0.5,
      learnerWeakness: 0.5,
      exposureCount: 0,
      recencyScore: 1.0,
      difficultyFit: 0.8,
      sourceQualityScore: 1.0,
      selectionScore: 0.75,
      isEligible: true,
      scoreBreakdown: const {
        'historicalPriority': 0.25,
        'weakness': 0.25,
        'recency': 0.15,
        'difficultyFit': 0.20,
        'quality': 0.15,
      },
    );
  }

  AdaptivePracticeSessionSpec buildSpec({
    String examId = 'upsc',
    String? learnerId = 'learner_101',
    required List<NormalizedQuestion> questions,
    PracticeSessionMode mode = PracticeSessionMode.standard,
  }) {
    final candidates =
        questions.map((q) => buildCandidate(question: q)).toList();

    final selectionResult = AdaptiveQuestionSelectionResult(
      examId: examId,
      selectedQuestions: questions,
      selectedCandidates: candidates,
      allCandidates: candidates,
      requestedCount: questions.isEmpty ? 1 : questions.length,
      eligibleCount: questions.isEmpty ? 1 : questions.length,
      config: AdaptiveQuestionSelectionConfig(
        examId: examId,
        targetQuestionCount: questions.isEmpty ? 1 : questions.length,
      ),
      selectedAt: fixedDate,
    );

    final config = AdaptivePracticeSessionConfig(
      examId: examId,
      learnerId: learnerId,
      sessionMode: mode,
      sectionSize: 5,
      estimatedSecondsPerQuestion: 60,
    );

    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: fixedDate,
    );
  }

  ConsolidatedPracticeOutcome buildSampleOutcome({
    String examId = 'upsc',
    String? learnerId = 'learner_101',
    int correctCount = 4,
    int incorrectCount = 0,
    int skippedCount = 0,
    int unansweredCount = 0,
    PracticeSessionMode mode = PracticeSessionMode.standard,
    String sessionTag = 'q',
  }) {
    final totalCount =
        correctCount + incorrectCount + skippedCount + unansweredCount;
    final questions = List.generate(
      totalCount,
      (i) => buildQuestion(
        id: '${sessionTag}_$i',
        examId: examId,
        objectiveIds: ['obj_unit_${sessionTag}_$i'],
      ),
    );
    final spec = buildSpec(
      examId: examId,
      learnerId: learnerId,
      questions: questions,
      mode: mode,
    );
    final initial = engine.initializeSession(spec: spec);
    var state =
        engine.startSession(state: initial, startedAt: fixedDate).valueOrThrow;

    int qIdx = 0;
    for (int i = 0; i < correctCount; i++, qIdx++) {
      state = engine
          .submitAnswer(
            state: state,
            questionId: '${sessionTag}_$qIdx',
            answer: 'A',
            submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    for (int i = 0; i < incorrectCount; i++, qIdx++) {
      state = engine
          .submitAnswer(
            state: state,
            questionId: '${sessionTag}_$qIdx',
            answer: 'B',
            submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    for (int i = 0; i < skippedCount; i++, qIdx++) {
      state = engine
          .skipQuestion(
            state: state,
            questionId: '${sessionTag}_$qIdx',
            skippedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    if (unansweredCount > 0) {
      state = engine
          .abandonSession(
            state: state,
            abandonedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }

    return consolidator.consolidate(state: state).valueOrThrow;
  }

  setUp(() {
    repository = InMemoryAuthoritativeLearningStateRepository();
    recoveryService = AuthoritativeLearningStateRecoveryService(
      repository: repository,
    );
    reconciler = const AdaptiveLearningStateReconciler();
    pipeline = AdaptiveLearningStateReconciliationPipeline(
      repository: repository,
      recoveryService: recoveryService,
      reconciler: reconciler,
      proposer: proposer,
      consolidator: consolidator,
    );
  });

  group('P39 Pipeline — Input Validation & Identity Safety', () {
    test('1. Valid outcome reconciliation produces persisted state at rev 2',
        () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      final outcome = buildSampleOutcome(correctCount: 3, incorrectCount: 1);
      final result = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isIdempotentReplay, isFalse);
      expect(result.isConflict, isFalse);
      expect(result.previousRevision, equals(1));
      expect(result.resultingRevision, equals(2));
      expect(result.resultingState, isNotNull);
      expect(result.resultingState!.revision, equals(2));
      expect(result.resultingState!.hasProcessedSession(outcome.sessionId),
          isTrue);

      // Verify durability in repository
      final persisted = await repository.load(
        learnerId: 'learner_101',
        examId: 'upsc',
      );
      expect(persisted, isNotNull);
      expect(persisted!.revision, equals(2));
      expect(persisted.processedSessionIds, contains(outcome.sessionId));
    });

    test(
        '2. Rejects learner mismatch with typed error and preserves base state',
        () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      final outcome = buildSampleOutcome(
        learnerId: 'learner_beta',
        correctCount: 2,
      );
      final result = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.persistenceError?.code,
        equals(AuthoritativePersistenceErrorCode.inconsistentState),
      );
      expect(result.resultingRevision, equals(1));

      final persisted = await repository.load(
        learnerId: 'learner_alpha',
        examId: 'upsc',
      );
      expect(persisted, isNull);
    });

    test('3. Rejects exam mismatch with typed error and preserves base state',
        () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      final outcome = buildSampleOutcome(
        examId: 'bpsc',
        correctCount: 2,
      );
      final result = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.persistenceError?.code,
        equals(AuthoritativePersistenceErrorCode.inconsistentState),
      );
      expect(result.resultingRevision, equals(1));
    });
  });

  group('P39 Pipeline — Mandatory Idempotency (Phase 4)', () {
    test('4. Idempotent repeated reconciliation does not double-apply progress',
        () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 0);

      // Run 1: applied
      final result1 = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        timestamp: fixedDate,
      );
      expect(result1.isSuccess, isTrue);
      expect(result1.resultingRevision, equals(2));
      final v2State = result1.resultingState!;
      final obj0Attempts = v2State.progressMap.values.first.attemptCount;

      // Run 2: same outcome
      final result2 = await pipeline.reconcilePracticeOutcome(
        baseState: v2State,
        outcome: outcome,
        timestamp: fixedDate.add(const Duration(minutes: 5)),
      );

      expect(result2.isSuccess, isTrue);
      expect(result2.isIdempotentReplay, isTrue);
      expect(result2.decision, equals(ReconciliationDecision.unchanged));
      expect(
          result2.resultingRevision, equals(2)); // Revision strictly unchanged
      expect(
        result2.resultingState!.progressMap.values.first.attemptCount,
        equals(obj0Attempts),
      );

      // Verify repository remains at rev 2
      final persisted = await repository.load(
        learnerId: 'learner_101',
        examId: 'upsc',
      );
      expect(persisted!.revision, equals(2));
    });
  });

  group('P39 Pipeline — Version & Conflict Safety (Phase 5)', () {
    test(
        '5. Stale expectedRevision triggers conflict decision without data loss',
        () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
        revision: 5,
      );

      final outcome = buildSampleOutcome(correctCount: 2);

      // Caller expects revision 3, but state is at revision 5
      final result = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        expectedRevision: 3,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isConflict, isTrue);
      expect(
        result.persistenceError?.code,
        equals(AuthoritativePersistenceErrorCode.staleWrite),
      );
      expect(result.resultingRevision, equals(5));
    });

    test('6. Matching expectedRevision advances revision cleanly', () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
        revision: 3,
      );

      final outcome = buildSampleOutcome(correctCount: 2);

      final result = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        expectedRevision: 3,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isTrue);
      expect(result.previousRevision, equals(3));
      expect(result.resultingRevision, equals(4));
    });
  });

  group('P39 Pipeline — Persistence Durability & Recovery (Phase 6)', () {
    test(
        '7. Repository IO failure preserves base state without corrupting storage',
        () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      // Simulate IO failure on save
      repository.failNextSave = true;

      final outcome = buildSampleOutcome(correctCount: 2);
      final result = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.persistenceError?.code,
        equals(AuthoritativePersistenceErrorCode.ioFailure),
      );
      expect(result.baseState.revision, equals(1));

      // Storage remains clean
      final loaded = await repository.load(
        learnerId: 'learner_101',
        examId: 'upsc',
      );
      expect(loaded, isNull);
    });

    test('8. executeFromRepository cold start initializes and persists state',
        () async {
      final outcome = buildSampleOutcome(
        learnerId: 'learner_cold',
        correctCount: 2,
      );

      final result = await pipeline.executeFromRepository(
        learnerId: 'learner_cold',
        examId: 'upsc',
        outcome: outcome,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isTrue);
      expect(result.previousRevision, equals(1));
      expect(result.resultingRevision, equals(2));

      final persisted = await repository.load(
        learnerId: 'learner_cold',
        examId: 'upsc',
      );
      expect(persisted, isNotNull);
      expect(persisted!.revision, equals(2));
    });
  });

  group('P39 Pipeline — Audit Trail & Fingerprints (Phase 7)', () {
    test(
        '9. Produces complete audit trail with deterministic cryptographic fingerprint',
        () async {
      final base = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      final outcome = buildSampleOutcome(correctCount: 2);
      final result = await pipeline.reconcilePracticeOutcome(
        baseState: base,
        outcome: outcome,
        timestamp: fixedDate,
      );

      final audit = result.auditTrail;
      expect(audit.auditId, isNotEmpty);
      expect(audit.learnerId, equals('learner_101'));
      expect(audit.examId, equals('upsc'));
      expect(audit.sessionId, equals(outcome.sessionId));
      expect(audit.baseRevision, equals(1));
      expect(audit.resultingRevision, equals(2));
      expect(audit.baseStateFingerprint, equals(base.stateFingerprint));
      expect(
        audit.resultingStateFingerprint,
        equals(result.resultingState!.stateFingerprint),
      );
      expect(audit.auditFingerprint, isNotEmpty);
      expect(audit.changedObjectiveIds, isNotEmpty);
      expect(audit.acceptedCount, greaterThanOrEqualTo(1));
    });

    test('10. Audit trail serialization round-trip', () {
      final audit = ReconciliationAuditTrail(
        auditId: 'aud_unit_1',
        learnerId: 'learner_101',
        examId: 'upsc',
        sessionId: 'sess_1',
        baseRevision: 1,
        resultingRevision: 2,
        baseStateFingerprint: 'fp_base_unit',
        resultingStateFingerprint: 'fp_res_unit',
        decision: ReconciliationDecision.merged,
        changedObjectiveIds: ['obj_1', 'obj_2'],
        acceptedCount: 2,
        rejectedCount: 0,
        notes: ['Note 1'],
        recordedAt: fixedDate,
      );

      final json = audit.toJson();
      final restored = ReconciliationAuditTrail.fromJson(json);

      expect(restored.auditId, equals(audit.auditId));
      expect(restored.auditFingerprint, equals(audit.auditFingerprint));
      expect(restored.changedObjectiveIds, equals(audit.changedObjectiveIds));
      expect(restored, equals(audit));
    });
  });

  group('P39 Pipeline — Invariants & Sequential Escalation', () {
    test(
        '11. Invariant: Monotonic revision strictly increments across 3 sessions',
        () async {
      var state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_seq',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      for (var i = 1; i <= 3; i++) {
        final outcome = buildSampleOutcome(
          learnerId: 'learner_seq',
          correctCount: 2,
          sessionTag: 'seq_$i',
        );

        final res = await pipeline.reconcilePracticeOutcome(
          baseState: state,
          outcome: outcome,
          expectedRevision: i,
          timestamp: fixedDate.add(Duration(hours: i)),
        );

        expect(res.isSuccess, isTrue);
        expect(res.previousRevision, equals(i));
        expect(res.resultingRevision, equals(i + 1));
        state = res.resultingState!;
      }

      expect(state.revision, equals(4));
      expect(state.processedSessionIds.length, equals(3));
    });
  });
}
