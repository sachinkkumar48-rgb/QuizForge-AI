/// P39 Authoritative Learning-State Application Gateway Integration Test Suite (TITAN-KO-039.0 P39).
///
/// Full pipeline integration test verifying end-to-end evidence feedback, reconciliation,
/// and authoritative transactional application to P19 persistence:
/// P30 (Acquisition) -> P29 (Normalization) -> P31 (Historical Intelligence)
/// -> P32 (Adaptive Priority) -> P23 (Learner State) -> P33 (Question Selection)
/// -> P34 (Practice Session Orchestrator) -> P35 (Adaptive Practice Execution Engine)
/// -> P36 (Outcome Consolidation & Evidence Bridge) -> P37 (Learning-State Update Proposal)
/// -> P38 (Adaptive Learning State Reconciliation Engine)
/// -> P39 (Authoritative Learning-State Application Gateway) -> P19 (ProgressRepository).
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

class FailingProgressRepository extends InMemoryProgressRepository {
  bool failOnBatch = false;

  @override
  void applyAtomicBatch({
    required String learnerId,
    required String sessionId,
    required List<LearnerProgress> progressList,
  }) {
    if (failOnBatch) {
      throw Exception('Simulated atomic persistence IO failure');
    }
    super.applyAtomicBatch(
      learnerId: learnerId,
      sessionId: sessionId,
      progressList: progressList,
    );
  }
}

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);

  group(
      'P39 Authoritative Learning-State Application Gateway Integration Pipeline',
      () {
    test(
        '1. Full E2E Pipeline (P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P35 -> P36 -> P37 -> P38 -> P39 -> P19)',
        () {
      // ----------------------------------------------------------------------
      // STAGE 1: P29/P30 Multi-Exam Normalization
      // ----------------------------------------------------------------------
      final rawBatch = <RawQuestionInput>[];
      int qCounter = 0;

      for (int year = 2020; year <= 2024; year++) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'History',
          topic: 'Modern History of Bihar',
          questionText: 'BPSC 1857 Revolt in Bihar question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          difficulty: 'Medium',
          objectiveIds: const ['obj_bihar_hist'],
          source: PyqSourceReference.official(
              examId: 'bpsc', year: year, paper: 'GS1'),
        ));

        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'History',
          topic: 'Indian National Movement',
          questionText:
              'BPSC Non-Cooperation Movement question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          difficulty: 'Hard',
          objectiveIds: const ['obj_modern_hist'],
          source: PyqSourceReference.official(
              examId: 'bpsc', year: year, paper: 'GS1'),
        ));

        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'Science',
          topic: 'General Science Physics',
          questionText: 'BPSC Physics question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'C',
          difficulty: 'Easy',
          objectiveIds: const ['obj_physics'],
          source: PyqSourceReference.official(
              examId: 'bpsc', year: year, paper: 'GS1'),
        ));
      }

      final p29Service = MultiExamPyqIntelligenceService();
      final ingestionResult = p29Service.ingestRawQuestions(rawBatch);
      final normalizedBatch = ingestionResult.uniqueQuestions;

      expect(normalizedBatch.length, equals(15));

      // ----------------------------------------------------------------------
      // STAGE 2: P31 Multi-Exam Historical PYQ Intelligence
      // ----------------------------------------------------------------------
      const p31Engine = PyqHistoricalIntelligenceEngine();
      final bpscIntelligence = p31Engine.buildExamProfile(
        normalizedBatch,
        examId: 'bpsc',
        frameworkObjectiveIds: const [
          'obj_bihar_hist',
          'obj_modern_hist',
          'obj_physics',
        ],
      );

      // ----------------------------------------------------------------------
      // STAGE 3: P23 Learner Weak Spot Diagnoses & Progress
      // ----------------------------------------------------------------------
      final weakSpotProfile = WeakSpotProfile(
        learnerId: 'learner_aspirant_bpsc_2026',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_bihar_hist',
            attemptCount: 10,
            correctCount: 2,
          ),
        ],
      );

      final initialProgressList = [
        LearnerProgress(
          learnerId: 'learner_aspirant_bpsc_2026',
          objectiveId: 'obj_bihar_hist',
          status: LearnerObjectiveStatus.inProgress,
          attemptCount: 10,
          correctCount: 2,
          lastAttemptAt: fixedDate,
        ),
        LearnerProgress(
          learnerId: 'learner_aspirant_bpsc_2026',
          objectiveId: 'obj_modern_hist',
          status: LearnerObjectiveStatus.achieved,
          attemptCount: 10,
          correctCount: 9,
          lastAttemptAt: fixedDate,
          achievedAt: fixedDate,
        ),
      ];

      final progressRepo = InMemoryProgressRepository();
      for (final p in initialProgressList) {
        progressRepo.saveProgress(p);
      }

      // ----------------------------------------------------------------------
      // STAGE 4: P32 PYQ Learning Priority Engine
      // ----------------------------------------------------------------------
      final p32Engine = PyqLearningPriorityEngine();
      final p32PriorityProfile = p32Engine.evaluateFromExamProfile(
        examProfile: bpscIntelligence,
        weakSpotProfile: weakSpotProfile,
        progressList: initialProgressList,
        evaluatedAt: fixedDate,
      );

      // ----------------------------------------------------------------------
      // STAGE 5: P33 Adaptive Question Selection
      // ----------------------------------------------------------------------
      const p33Service = AdaptiveQuestionSelectionService();
      final selectionResult = p33Service.selectQuestions(
        corpus: normalizedBatch,
        config: AdaptiveQuestionSelectionConfig(
          examId: 'bpsc',
          targetQuestionCount: 5,
        ),
        pyqPriorityProfile: p32PriorityProfile,
        weakSpotProfile: weakSpotProfile,
        progressList: initialProgressList,
        selectedAt: fixedDate,
      );

      // ----------------------------------------------------------------------
      // STAGE 6: P34 Adaptive Practice Session Orchestration
      // ----------------------------------------------------------------------
      const sessionOrchestrator = AdaptivePracticeSessionOrchestrator();
      final sessionSpec = sessionOrchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: AdaptivePracticeSessionConfig(
          examId: 'bpsc',
          learnerId: 'learner_aspirant_bpsc_2026',
          sessionMode: PracticeSessionMode.remedialPractice,
          sectionSize: 3,
          estimatedSecondsPerQuestion: 60,
        ),
        orchestratedAt: fixedDate,
      );

      // ----------------------------------------------------------------------
      // STAGE 7: P35 Adaptive Practice Session Execution
      // ----------------------------------------------------------------------
      const executionEngine = AdaptivePracticeExecutionEngine();
      final initialState = executionEngine.initializeSession(
        spec: sessionSpec,
        feedbackPolicy: PracticeFeedbackPolicy.immediate,
      );

      var currentState = executionEngine
          .startSession(state: initialState, startedAt: fixedDate)
          .valueOrThrow;

      for (int i = 0; i < 5; i++) {
        final q = currentState.currentQuestion!;
        final answerToSubmit = q.officialAnswer.correctOptionKeys.first;

        currentState = executionEngine
            .submitAnswer(
              state: currentState,
              questionId: q.id,
              answer: answerToSubmit,
              submittedAt: fixedDate.add(Duration(seconds: (i + 1) * 20)),
            )
            .valueOrThrow;
      }

      // ----------------------------------------------------------------------
      // STAGE 8: P36 Adaptive Practice Outcome Consolidation
      // ----------------------------------------------------------------------
      const outcomeConsolidator = PracticeOutcomeConsolidator();
      final outcome = outcomeConsolidator
          .consolidate(
            state: currentState,
            consolidatedAt: fixedDate.add(const Duration(seconds: 180)),
          )
          .valueOrThrow;

      // ----------------------------------------------------------------------
      // STAGE 9: P37 Adaptive Learning Evidence Feedback Loop & Proposal
      // ----------------------------------------------------------------------
      const updateProposer = LearningStateUpdateProposer();
      final proposal = updateProposer
          .proposeUpdate(
            outcome: outcome,
            proposedAt: fixedDate.add(const Duration(seconds: 200)),
          )
          .valueOrThrow;

      // ----------------------------------------------------------------------
      // STAGE 10: P38 Adaptive Learning State Reconciliation Engine
      // ----------------------------------------------------------------------
      final authoritativeLearnerState =
          AuthoritativeLearnerState.fromRepository(
        repository: progressRepo,
        learnerId: 'learner_aspirant_bpsc_2026',
        examId: 'bpsc',
        lastUpdatedAt: fixedDate,
      );

      const stateReconciler = AdaptiveLearningStateReconciler();
      final reconciliationResult = stateReconciler.reconcile(
        authoritativeState: authoritativeLearnerState,
        proposal: proposal,
        reconciledAt: fixedDate.add(const Duration(seconds: 250)),
      );

      expect(reconciliationResult.isSuccess, isTrue);
      final reconciledProposal = reconciliationResult.valueOrThrow;

      // ----------------------------------------------------------------------
      // STAGE 11: P39 Authoritative Learning-State Application Gateway
      // ----------------------------------------------------------------------
      final gateway = AuthoritativeLearningStateGateway(
        progressRepository: progressRepo,
      );

      final applyResult = gateway.applyProposal(
        proposal: reconciledProposal,
        currentState: authoritativeLearnerState,
        appliedAt: fixedDate.add(const Duration(seconds: 300)),
      );

      expect(applyResult.isSuccess, isTrue);
      expect(applyResult.decision,
          equals(AuthoritativeApplicationDecision.applied));
      expect(applyResult.appliedChangesCount, greaterThan(0));
      expect(applyResult.isDuplicate, isFalse);
      expect(applyResult.operationId, startsWith('op_'));
      expect(applyResult.fingerprint, hasLength(64));

      // ----------------------------------------------------------------------
      // STAGE 12: Direct P19 Persistence Verification
      // ----------------------------------------------------------------------
      final reloadedRecords =
          progressRepo.getProgressForLearner('learner_aspirant_bpsc_2026');

      expect(reloadedRecords.isNotEmpty, isTrue);
      for (final r in reloadedRecords) {
        expect(r.learnerId, equals('learner_aspirant_bpsc_2026'));
        expect(r.attemptCount, greaterThan(0));
        expect(r.correctCount, lessThanOrEqualTo(r.attemptCount));
      }

      // Verify session was marked in P19 persistence
      expect(
        progressRepo.isSessionProcessed(
          'learner_aspirant_bpsc_2026',
          reconciledProposal.provenance.sessionId,
        ),
        isTrue,
      );

      // Verify Idempotency: Re-applying immediately returns alreadyApplied
      final replayResult = gateway.applyProposal(
        proposal: reconciledProposal,
      );
      expect(replayResult.isSuccess, isTrue);
      expect(replayResult.decision,
          equals(AuthoritativeApplicationDecision.alreadyApplied));
      expect(replayResult.isDuplicate, isTrue);
      expect(replayResult.appliedChangesCount, equals(0));
      expect(replayResult.operationId, equals(applyResult.operationId));
    });

    test(
        '2. Multi-Exam Isolation: UPSC and BPSC states and proposals reconcile and apply independently',
        () {
      final repo = InMemoryProgressRepository();
      final gateway =
          AuthoritativeLearningStateGateway(progressRepository: repo);

      final stateUpsc = AuthoritativeLearnerState(
        learnerId: 'learner_aspirant_2026',
        examId: 'upsc',
        progressMap: {
          'obj_shared_hist': LearnerProgress(
            learnerId: 'learner_aspirant_2026',
            objectiveId: 'obj_shared_hist',
            attemptCount: 10,
            correctCount: 8,
          ),
        },
        processedSessionIds: const {},
        lastUpdatedAt: fixedDate,
      );

      final stateBpsc = AuthoritativeLearnerState(
        learnerId: 'learner_aspirant_2026',
        examId: 'bpsc',
        progressMap: {
          'obj_shared_hist': LearnerProgress(
            learnerId: 'learner_aspirant_2026',
            objectiveId: 'obj_shared_hist',
            attemptCount: 5,
            correctCount: 3,
          ),
        },
        processedSessionIds: const {},
        lastUpdatedAt: fixedDate,
      );

      final propUpsc = ReconciledLearningStateProposal(
        reconciliationId: 'rec_upsc_1',
        learnerId: 'learner_aspirant_2026',
        examId: 'upsc',
        baseStateFingerprint: stateUpsc.stateFingerprint,
        sourceProposalFingerprint: 'prop_hash_upsc',
        reconciledAt: fixedDate,
        overallDecision: ReconciliationDecision.merged,
        reconciledProgress: {
          'obj_shared_hist': LearnerProgress(
            learnerId: 'learner_aspirant_2026',
            objectiveId: 'obj_shared_hist',
            attemptCount: 15,
            correctCount: 13,
          ),
        },
        processedSessionIds: const {'sess_upsc'},
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: const [],
        provenance: ReconciliationProvenance(
          proposalId: 'p_upsc',
          sessionId: 'sess_upsc',
          sourceProposalFingerprint: 'prop_hash_upsc',
          baseStateFingerprint: stateUpsc.stateFingerprint,
          reconciledAt: fixedDate,
        ),
        fingerprint: 'fp_upsc_001',
      );

      final propBpsc = ReconciledLearningStateProposal(
        reconciliationId: 'rec_bpsc_1',
        learnerId: 'learner_aspirant_2026',
        examId: 'bpsc',
        baseStateFingerprint: stateBpsc.stateFingerprint,
        sourceProposalFingerprint: 'prop_hash_bpsc',
        reconciledAt: fixedDate,
        overallDecision: ReconciliationDecision.merged,
        reconciledProgress: {
          'obj_shared_hist': LearnerProgress(
            learnerId: 'learner_aspirant_2026',
            objectiveId: 'obj_shared_hist',
            attemptCount: 10,
            correctCount: 8,
          ),
        },
        processedSessionIds: const {'sess_bpsc'},
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: const [],
        provenance: ReconciliationProvenance(
          proposalId: 'p_bpsc',
          sessionId: 'sess_bpsc',
          sourceProposalFingerprint: 'prop_hash_bpsc',
          baseStateFingerprint: stateBpsc.stateFingerprint,
          reconciledAt: fixedDate,
        ),
        fingerprint: 'fp_bpsc_001',
      );

      final resUpsc =
          gateway.applyProposal(proposal: propUpsc, currentState: stateUpsc);
      final resBpsc =
          gateway.applyProposal(proposal: propBpsc, currentState: stateBpsc);

      expect(resUpsc.isSuccess, isTrue);
      expect(resBpsc.isSuccess, isTrue);
      expect(resUpsc.resultingStateFingerprint,
          isNot(equals(resBpsc.resultingStateFingerprint)));
      expect(resUpsc.operationId, isNot(equals(resBpsc.operationId)));
    });

    test(
        '3. Sequential Idempotency: Reconciling and applying twice produces duplicate no-op without state drift',
        () {
      final repo = InMemoryProgressRepository();
      final gateway =
          AuthoritativeLearningStateGateway(progressRepository: repo);

      final initialProgress = LearnerProgress(
        learnerId: 'learner_idem',
        objectiveId: 'obj_test_1',
        attemptCount: 10,
        correctCount: 8,
        status: LearnerObjectiveStatus.achieved,
      );
      repo.saveProgress(initialProgress);

      final state = AuthoritativeLearnerState.fromRepository(
        repository: repo,
        learnerId: 'learner_idem',
        examId: 'upsc',
        lastUpdatedAt: fixedDate,
      );

      final prop = ReconciledLearningStateProposal(
        reconciliationId: 'rec_idem_1',
        learnerId: 'learner_idem',
        examId: 'upsc',
        baseStateFingerprint: state.stateFingerprint,
        sourceProposalFingerprint: 'prop_hash_idem',
        reconciledAt: fixedDate,
        overallDecision: ReconciliationDecision.merged,
        reconciledProgress: {
          'obj_test_1': LearnerProgress(
            learnerId: 'learner_idem',
            objectiveId: 'obj_test_1',
            attemptCount: 15,
            correctCount: 13,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        processedSessionIds: const {'sess_idem_1'},
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: const [],
        provenance: ReconciliationProvenance(
          proposalId: 'p_idem',
          sessionId: 'sess_idem_1',
          sourceProposalFingerprint: 'prop_hash_idem',
          baseStateFingerprint: state.stateFingerprint,
          reconciledAt: fixedDate,
        ),
        fingerprint: 'fp_idem_001',
      );

      // First apply
      final r1 = gateway.applyProposal(proposal: prop, currentState: state);
      expect(r1.decision, equals(AuthoritativeApplicationDecision.applied));
      expect(r1.appliedChangesCount, equals(1));
      final fingerprintAfterFirst = r1.resultingStateFingerprint;

      // Second apply (re-application)
      final r2 = gateway.applyProposal(proposal: prop);
      expect(
          r2.decision, equals(AuthoritativeApplicationDecision.alreadyApplied));
      expect(r2.appliedChangesCount, equals(0));
      expect(r2.resultingStateFingerprint, equals(fingerprintAfterFirst));
      expect(r2.operationId, equals(r1.operationId));

      // Direct verify repository
      final p = repo.getProgress('learner_idem', 'obj_test_1')!;
      expect(p.attemptCount, equals(15));
      expect(p.correctCount, equals(13));
    });

    test(
        '4. Mid-Operation Failure & Rollback: Simulated failure leaves initial state unmodified',
        () {
      final failingRepo = FailingProgressRepository();
      final gateway =
          AuthoritativeLearningStateGateway(progressRepository: failingRepo);

      final initialProgress = LearnerProgress(
        learnerId: 'learner_fail',
        objectiveId: 'obj_test_fail',
        attemptCount: 10,
        correctCount: 8,
        status: LearnerObjectiveStatus.achieved,
      );
      failingRepo.saveProgress(initialProgress);

      final state = AuthoritativeLearnerState.fromRepository(
        repository: failingRepo,
        learnerId: 'learner_fail',
        examId: 'upsc',
        lastUpdatedAt: fixedDate,
      );

      final prop = ReconciledLearningStateProposal(
        reconciliationId: 'rec_fail_1',
        learnerId: 'learner_fail',
        examId: 'upsc',
        baseStateFingerprint: state.stateFingerprint,
        sourceProposalFingerprint: 'prop_hash_fail',
        reconciledAt: fixedDate,
        overallDecision: ReconciliationDecision.merged,
        reconciledProgress: {
          'obj_test_fail': LearnerProgress(
            learnerId: 'learner_fail',
            objectiveId: 'obj_test_fail',
            attemptCount: 20,
            correctCount: 18,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        processedSessionIds: const {'sess_fail_1'},
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: const [],
        provenance: ReconciliationProvenance(
          proposalId: 'p_fail',
          sessionId: 'sess_fail_1',
          sourceProposalFingerprint: 'prop_hash_fail',
          baseStateFingerprint: state.stateFingerprint,
          reconciledAt: fixedDate,
        ),
        fingerprint: 'fp_fail_001',
      );

      // Arm failure
      failingRepo.failOnBatch = true;

      final res = gateway.applyProposal(proposal: prop, currentState: state);
      expect(res.isSuccess, isFalse);
      expect(res.decision, equals(AuthoritativeApplicationDecision.failed));
      expect(res.error!.code,
          equals(AuthoritativeApplicationErrorCode.persistenceFailure));

      // Prior state must be completely unmodified
      final p = failingRepo.getProgress('learner_fail', 'obj_test_fail')!;
      expect(p.attemptCount, equals(10));
      expect(p.correctCount, equals(8));
      expect(failingRepo.isSessionProcessed('learner_fail', 'sess_fail_1'),
          isFalse);
    });

    test(
        '5. Deterministic Pipeline Replay: 10 consecutive full pipeline executions produce identical JSON and SHA-256',
        () {
      final jsonPayloads = <String>[];
      final fingerprints = <String>[];

      for (int i = 0; i < 10; i++) {
        final repo = InMemoryProgressRepository();
        final initialProgress = LearnerProgress(
          learnerId: 'learner_deterministic',
          objectiveId: 'obj_det_1',
          attemptCount: 10,
          correctCount: 7,
          status: LearnerObjectiveStatus.inProgress,
        );
        repo.saveProgress(initialProgress);

        final state = AuthoritativeLearnerState.fromRepository(
          repository: repo,
          learnerId: 'learner_deterministic',
          examId: 'upsc',
          lastUpdatedAt: fixedDate,
        );

        final prop = ReconciledLearningStateProposal(
          reconciliationId: 'rec_det_1',
          learnerId: 'learner_deterministic',
          examId: 'upsc',
          baseStateFingerprint: state.stateFingerprint,
          sourceProposalFingerprint: 'prop_hash_det',
          reconciledAt: fixedDate,
          overallDecision: ReconciliationDecision.merged,
          reconciledProgress: {
            'obj_det_1': LearnerProgress(
              learnerId: 'learner_deterministic',
              objectiveId: 'obj_det_1',
              attemptCount: 15,
              correctCount: 12,
              status: LearnerObjectiveStatus.achieved,
            ),
          },
          processedSessionIds: const {'sess_det_1'},
          questionDecisions: const [],
          objectiveDecisions: const {},
          topicDecisions: const {},
          conflicts: const [],
          provenance: ReconciliationProvenance(
            proposalId: 'p_det',
            sessionId: 'sess_det_1',
            sourceProposalFingerprint: 'prop_hash_det',
            baseStateFingerprint: state.stateFingerprint,
            reconciledAt: fixedDate,
          ),
          fingerprint: 'fp_det_001',
        );

        final gateway =
            AuthoritativeLearningStateGateway(progressRepository: repo);
        final res = gateway.applyProposal(
          proposal: prop,
          currentState: state,
          appliedAt: fixedDate,
        );

        jsonPayloads.add(jsonEncode(res.toJson()));
        fingerprints.add(res.fingerprint);
      }

      for (int i = 1; i < 10; i++) {
        expect(jsonPayloads[i], equals(jsonPayloads[0]));
        expect(fingerprints[i], equals(fingerprints[0]));
      }
    });
  });
}
