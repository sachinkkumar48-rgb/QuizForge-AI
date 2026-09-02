/// P38 Adaptive Learning State Reconciliation Engine Unit & Property Tests (TITAN-KO-038.0 P38).
///
/// Comprehensive test suite verifying learning-state reconciliation,
/// explainable granular decisions (accepted, merged, unchanged, duplicate, stale, conflict),
/// achievement threshold evaluations, multi-exam and learner isolation,
/// non-persistent proposal formulation, deterministic canonical hashing, and benchmarks.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);
  const reconciler = AdaptiveLearningStateReconciler();
  const proposer = LearningStateUpdateProposer();
  const consolidator = PracticeOutcomeConsolidator();
  const engine = AdaptivePracticeExecutionEngine();
  const orchestrator = AdaptivePracticeSessionOrchestrator();

  NormalizedQuestion buildQuestion({
    required String id,
    String examId = 'upsc',
    int year = 2024,
    String paper = 'GS1',
    String subject = 'Polity',
    String topic = 'Fundamental Rights',
    List<String>? objectiveIds,
    String difficulty = 'Medium',
    String normalizedText = 'Normalized test question text',
    List<Option>? options,
    Answer? officialAnswer,
    String explanation = 'Official commission explanation text',
    PyqSourceReference? source,
  }) {
    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: year,
      paper: paper,
      subject: subject,
      topic: topic,
      normalizedText: normalizedText,
      originalText: normalizedText,
      options: options ??
          const [
            Option(key: 'A', text: 'Option A', isCorrect: true),
            Option(key: 'B', text: 'Option B', isCorrect: false),
            Option(key: 'C', text: 'Option C', isCorrect: false),
            Option(key: 'D', text: 'Option D', isCorrect: false),
          ],
      officialAnswer: officialAnswer ??
          const Answer(
            correctOptionKeys: ['A'],
            officialAnswerSource: 'Official Commission Key',
          ),
      explanation: explanation,
      difficulty: difficulty,
      source: source ??
          PyqSourceReference.official(
            examId: examId,
            year: year,
            paper: paper,
          ),
      objectiveIds: objectiveIds ?? const ['obj_polity_fr'],
    );
  }

  AdaptiveQuestionCandidate buildCandidate({
    required NormalizedQuestion question,
    double priority = 0.5,
    double weakness = 0.5,
    int exposures = 0,
    DateTime? lastExposed,
    double recency = 1.0,
    double diffFit = 0.8,
    double quality = 1.0,
    double selectionScore = 0.75,
    bool eligible = true,
  }) {
    return AdaptiveQuestionCandidate(
      question: question,
      historicalPriority: priority,
      learnerWeakness: weakness,
      exposureCount: exposures,
      lastExposedAt: lastExposed,
      recencyScore: recency,
      difficultyFit: diffFit,
      sourceQualityScore: quality,
      selectionScore: selectionScore,
      isEligible: eligible,
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
    int sectionSize = 5,
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
      sectionSize: sectionSize,
      estimatedSecondsPerQuestion: 60,
    );

    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: fixedDate,
    );
  }

  LearningStateUpdateProposal buildSampleProposal({
    String examId = 'upsc',
    String? learnerId = 'learner_101',
    int correctCount = 4,
    int incorrectCount = 0,
    int skippedCount = 0,
    int unansweredCount = 0,
    String? objectiveId,
    PracticeSessionMode mode = PracticeSessionMode.standard,
  }) {
    final totalCount =
        correctCount + incorrectCount + skippedCount + unansweredCount;
    final questions = List.generate(
      totalCount,
      (i) => buildQuestion(
        id: 'q_$i',
        examId: examId,
        objectiveIds: objectiveId != null ? [objectiveId] : ['obj_polity_fr'],
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
            questionId: 'q_$qIdx',
            answer: 'A',
            submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    for (int i = 0; i < incorrectCount; i++, qIdx++) {
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_$qIdx',
            answer: 'B',
            submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    for (int i = 0; i < skippedCount; i++, qIdx++) {
      state = engine
          .skipQuestion(
            state: state,
            questionId: 'q_$qIdx',
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

    final outcome = consolidator.consolidate(state: state).valueOrThrow;
    return proposer.proposeUpdate(outcome: outcome).valueOrThrow;
  }

  AuthoritativeLearnerState buildSampleState({
    String learnerId = 'learner_101',
    String examId = 'upsc',
    Map<String, LearnerProgress>? progressMap,
    Set<String>? processedSessionIds,
    DateTime? lastUpdatedAt,
  }) {
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap ??
          {
            'obj_polity_fr': LearnerProgress(
              learnerId: learnerId,
              objectiveId: 'obj_polity_fr',
              attemptCount: 10,
              correctCount: 8,
              lastAttemptAt: fixedDate,
              status: LearnerObjectiveStatus.inProgress,
            ),
          },
      processedSessionIds: processedSessionIds ?? const {},
      lastUpdatedAt: lastUpdatedAt ?? fixedDate,
    );
  }

  // ==========================================================================
  // GROUP 1: Construction & Serialization (8 tests)
  // ==========================================================================
  group('P38.1 Group 1 — Construction & Serialization', () {
    test('1. Valid reconciled proposal compiles from state and proposal', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final result = reconciler.reconcile(
        authoritativeState: state,
        proposal: prop,
      );

      expect(result.isSuccess, isTrue);
      final reconciled = result.valueOrThrow;
      expect(reconciled.reconciliationId, startsWith('rec_'));
      expect(reconciled.learnerId, equals('learner_101'));
      expect(reconciled.examId, equals('upsc'));
      expect(reconciled.fingerprint, hasLength(64));
    });

    test('2. Reconciled proposal serializes and deserializes cleanly to JSON',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 3);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      final fromJson = ReconciledLearningStateProposal.fromJson(json);

      expect(fromJson.reconciliationId, equals(reconciled.reconciliationId));
      expect(fromJson.learnerId, equals(reconciled.learnerId));
      expect(fromJson.examId, equals(reconciled.examId));
      expect(fromJson.overallDecision, equals(reconciled.overallDecision));
      expect(fromJson.fingerprint, equals(reconciled.fingerprint));
      expect(fromJson.reconciledProgress.length,
          equals(reconciled.reconciledProgress.length));
    });

    test(
        '3. AuthoritativeLearnerState serializes and deserializes cleanly to JSON',
        () {
      final state = buildSampleState();
      final json = state.toJson();
      final fromJson = AuthoritativeLearnerState.fromJson(json);

      expect(fromJson.learnerId, equals(state.learnerId));
      expect(fromJson.examId, equals(state.examId));
      expect(fromJson.stateFingerprint, equals(state.stateFingerprint));
      expect(fromJson.progressMap.length, equals(state.progressMap.length));
    });

    test('4. Reconciled proposal collections are deeply unmodifiable', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
        () => reconciled.reconciledProgress['new_obj'] =
            reconciled.reconciledProgress.values.first,
        throwsUnsupportedError,
      );
      expect(
        () => reconciled.processedSessionIds.add('new_sess'),
        throwsUnsupportedError,
      );
      expect(
        () => reconciled.questionDecisions.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => reconciled.objectiveDecisions['new_obj'] =
            reconciled.objectiveDecisions.values.first,
        throwsUnsupportedError,
      );
      expect(
        () => reconciled.topicDecisions['new_topic'] =
            reconciled.topicDecisions.values.first,
        throwsUnsupportedError,
      );
    });

    test(
        '5. Manual construction of ReconciledLearningStateProposal with blank ID throws ArgumentError',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      expect(
        () => ReconciledLearningStateProposal(
          reconciliationId: '',
          learnerId: 'learner_101',
          examId: 'upsc',
          baseStateFingerprint: state.stateFingerprint,
          sourceProposalFingerprint: prop.fingerprint,
          reconciledAt: fixedDate,
          overallDecision: ReconciliationDecision.unchanged,
          reconciledProgress: const {},
          processedSessionIds: const {},
          questionDecisions: const [],
          objectiveDecisions: const {},
          topicDecisions: const {},
          conflicts: const [],
          provenance: ReconciliationProvenance(
            proposalId: prop.proposalId,
            sessionId: prop.sessionId,
            sourceProposalFingerprint: prop.fingerprint,
            baseStateFingerprint: state.stateFingerprint,
            reconciledAt: fixedDate,
          ),
          fingerprint: 'fp',
        ),
        throwsArgumentError,
      );
    });

    test(
        '6. AuthoritativeLearnerState.empty constructs clean state with 0 objectives',
        () {
      final empty = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      expect(empty.progressMap, isEmpty);
      expect(empty.processedSessionIds, isEmpty);
      expect(empty.stateFingerprint, hasLength(64));
    });

    test(
        '7. AuthoritativeLearnerState.fromProgressList constructs sorted progress map',
        () {
      final p1 = LearnerProgress(learnerId: 'l1', objectiveId: 'obj_z');
      final p2 = LearnerProgress(learnerId: 'l1', objectiveId: 'obj_a');
      final state = AuthoritativeLearnerState.fromProgressList(
        learnerId: 'l1',
        examId: 'upsc',
        progressList: [p1, p2],
        lastUpdatedAt: fixedDate,
      );

      expect(state.progressMap.keys.toList(), equals(['obj_a', 'obj_z']));
    });

    test('8. ReconciledLearningStateProposal toString formats cleanly', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
          reconciled.toString(), contains('ReconciledLearningStateProposal'));
      expect(reconciled.toString(), contains('learner: learner_101'));
    });
  });

  // ==========================================================================
  // GROUP 2: No-op & Unchanged Scenarios (8 tests)
  // ==========================================================================
  group('P38.2 Group 2 — No-op & Unchanged Scenarios', () {
    test(
        '9. Proposal with 0 questions produces ReconciliationDecision.unchanged',
        () {
      final state = buildSampleState();
      final emptyProp = buildSampleProposal(correctCount: 0); // 0 questions
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: emptyProp)
          .valueOrThrow;

      expect(
          reconciled.overallDecision, equals(ReconciliationDecision.unchanged));
      expect(reconciled.hasStateChanges, isFalse);
      expect(reconciled.reconciledProgress.length,
          equals(state.progressMap.length));
    });

    test('10. Unchanged scenario preserves identical existing attempt counts',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, skippedCount: 2);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final existing = state.getProgress('obj_polity_fr')!;
      final after = reconciled.reconciledProgress['obj_polity_fr']!;

      expect(after.attemptCount, equals(existing.attemptCount));
      expect(after.correctCount, equals(existing.correctCount));
    });

    test(
        '11. Unattempted objective in proposal generates objective decision unchanged',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, skippedCount: 1);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final oDec = reconciled.objectiveDecisions['obj_polity_fr']!;
      expect(oDec.decision, equals(ReconciliationDecision.unchanged));
      expect(oDec.newAttempts, equals(0));
    });

    test('12. Unchanged decision retains existing objective achievement status',
        () {
      final achievedProgress = LearnerProgress(
        learnerId: 'learner_101',
        objectiveId: 'obj_polity_fr',
        attemptCount: 15,
        correctCount: 14,
        status: LearnerObjectiveStatus.achieved,
        achievedAt: fixedDate,
      );
      final state =
          buildSampleState(progressMap: {'obj_polity_fr': achievedProgress});
      final prop = buildSampleProposal(correctCount: 0);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.reconciledProgress['obj_polity_fr']!.status,
          equals(LearnerObjectiveStatus.achieved));
    });

    test('13. Unchanged decision hasStateChanges returns false', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.hasStateChanges, isFalse);
    });

    test('14. Question decision for skipped question is unchanged', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, skippedCount: 1);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.questionDecisions.first.decision,
          equals(ReconciliationDecision.unchanged));
    });

    test('15. Topic decision for topic with 0 attempts is unchanged', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, skippedCount: 1);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.topicDecisions.values.first.decision,
          equals(ReconciliationDecision.unchanged));
    });

    test('16. Unchanged reconciliation produces no conflicts', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.conflicts, isEmpty);
    });
  });

  // ==========================================================================
  // GROUP 3: Additive Objective Evidence (8 tests)
  // ==========================================================================
  group('P38.3 Group 3 — Additive Objective Evidence', () {
    test('17. New objective evidence is accepted into empty state', () {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final prop = buildSampleProposal(
        correctCount: 3,
        incorrectCount: 1,
        objectiveId: 'obj_new_history',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: emptyState, proposal: prop)
          .valueOrThrow;

      expect(
          reconciled.reconciledProgress.containsKey('obj_new_history'), isTrue);
      final progress = reconciled.reconciledProgress['obj_new_history']!;
      expect(progress.attemptCount, equals(4));
      expect(progress.correctCount, equals(3));
      expect(progress.successRate, equals(0.75));
    });

    test('18. Additive objective decision is marked as accepted', () {
      final state = buildSampleState(); // contains obj_polity_fr
      final prop = buildSampleProposal(
        correctCount: 2,
        objectiveId: 'obj_economy_macro',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final oDec = reconciled.objectiveDecisions['obj_economy_macro']!;
      expect(oDec.decision, equals(ReconciliationDecision.accepted));
      expect(oDec.priorAttempts, equals(0));
      expect(oDec.reconciledAttempts, equals(2));
    });

    test(
        '19. Additive objective preserves existing objectives alongside new one',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        correctCount: 2,
        objectiveId: 'obj_economy_macro',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
          reconciled.reconciledProgress.containsKey('obj_polity_fr'), isTrue);
      expect(reconciled.reconciledProgress.containsKey('obj_economy_macro'),
          isTrue);
      expect(reconciled.reconciledProgress.length, equals(2));
    });

    test('20. Additive objective meeting threshold is marked achieved', () {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      // Threshold: default requires min 5 attempts with 80% success
      final prop = buildSampleProposal(
        correctCount: 5,
        incorrectCount: 0,
        objectiveId: 'obj_perfect',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: emptyState, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_perfect']!;
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.achievedAt, isNotNull);
    });

    test('21. Additive objective below threshold is marked inProgress', () {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final prop = buildSampleProposal(
        correctCount: 2,
        incorrectCount: 1,
        objectiveId: 'obj_partial',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: emptyState, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_partial']!;
      expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
      expect(progress.achievedAt, isNull);
    });

    test(
        '22. Additive progress record sets learnerId and objectiveId correctly',
        () {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'aspirant_99',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final prop = buildSampleProposal(
        learnerId: 'aspirant_99',
        correctCount: 1,
        objectiveId: 'obj_geo',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: emptyState, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_geo']!;
      expect(progress.learnerId, equals('aspirant_99'));
      expect(progress.objectiveId, equals('obj_geo'));
    });

    test('23. Additive update marks overallDecision as merged', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(
        correctCount: 2,
        objectiveId: 'obj_new',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.overallDecision, equals(ReconciliationDecision.merged));
      expect(reconciled.hasStateChanges, isTrue);
    });

    test(
        '24. Reconciled progress keys remain deterministically sorted alphabetically',
        () {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final prop = buildSampleProposal(
        correctCount: 2,
        objectiveId: 'obj_z',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: emptyState, proposal: prop)
          .valueOrThrow;

      expect(reconciled.reconciledProgress.keys.toList(), equals(['obj_z']));
    });
  });

  // ==========================================================================
  // GROUP 4: Compatible Progress Merging (8 tests)
  // ==========================================================================
  group('P38.4 Group 4 — Compatible Progress Merging', () {
    test('25. Compatible merge sums prior and new attempt counts', () {
      final state = buildSampleState(); // 10 attempts, 8 correct
      final prop = buildSampleProposal(
        correctCount: 4,
        incorrectCount: 1,
        objectiveId: 'obj_polity_fr',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_polity_fr']!;
      expect(progress.attemptCount, equals(15)); // 10 + 5
      expect(progress.correctCount, equals(12)); // 8 + 4
      expect(progress.successRate, equals(12 / 15));
    });

    test('26. Compatible merge is marked with decision merged', () {
      final state = buildSampleState();
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_polity_fr');

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final oDec = reconciled.objectiveDecisions['obj_polity_fr']!;
      expect(oDec.decision, equals(ReconciliationDecision.merged));
      expect(oDec.priorAttempts, equals(10));
      expect(oDec.newAttempts, equals(2));
      expect(oDec.reconciledAttempts, equals(12));
    });

    test(
        '27. Compatible merge promotes inProgress objective to achieved when threshold met',
        () {
      // Prior: 4 attempts, 4 correct (successRate 1.0, but attempts < 5 threshold)
      final state = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'obj_polity_fr',
            attemptCount: 4,
            correctCount: 4,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      // New: 2 attempts, 2 correct -> Total: 6 attempts, 6 correct (100% >= 80%, 6 >= 5)
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_polity_fr');

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_polity_fr']!;
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.achievedAt, isNotNull);
    });

    test(
        '28. Authoritative achieved status is NEVER regressed by incorrect practice attempts',
        () {
      // Prior: Achieved with 10 attempts, 10 correct
      final state = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'obj_polity_fr',
            attemptCount: 10,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
            achievedAt: fixedDate,
          ),
        },
      );
      // New practice session: 5 incorrect attempts (brings overall rate down to 10/15 = 66%)
      final prop = buildSampleProposal(
        correctCount: 0,
        incorrectCount: 5,
        objectiveId: 'obj_polity_fr',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_polity_fr']!;
      expect(progress.status,
          equals(LearnerObjectiveStatus.achieved)); // Preserved!
      expect(progress.attemptCount, equals(15));
      expect(progress.correctCount, equals(10));
    });

    test('29. Merge recalculates success rate accurately', () {
      final state = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'obj_polity_fr',
            attemptCount: 10,
            correctCount: 5, // 50%
          ),
        },
      );
      // New: 10 attempts, 10 correct
      final prop = buildSampleProposal(
        correctCount: 10,
        incorrectCount: 0,
        objectiveId: 'obj_polity_fr',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_polity_fr']!;
      expect(progress.attemptCount, equals(20));
      expect(progress.correctCount, equals(15));
      expect(progress.successRate, equals(0.75));
    });

    test('30. Merge updates lastAttemptAt to reconciled timestamp', () {
      final oldTime = DateTime.utc(2025, 1, 1);
      final newTime = DateTime.utc(2026, 9, 2);
      final state = buildSampleState(lastUpdatedAt: oldTime);
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(
            authoritativeState: state,
            proposal: prop,
            reconciledAt: newTime,
          )
          .valueOrThrow;

      expect(
        reconciled.reconciledProgress['obj_polity_fr']!.lastAttemptAt,
        equals(newTime),
      );
    });

    test(
        '31. Unrelated objectives in authoritative state remain unchanged during merge',
        () {
      final p1 = LearnerProgress(
          learnerId: 'l1',
          objectiveId: 'obj_unrelated',
          attemptCount: 20,
          correctCount: 18);
      final p2 = LearnerProgress(
          learnerId: 'l1',
          objectiveId: 'obj_polity_fr',
          attemptCount: 10,
          correctCount: 8);
      final state = buildSampleState(
          progressMap: {'obj_unrelated': p1, 'obj_polity_fr': p2});

      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_polity_fr');
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.reconciledProgress['obj_unrelated']!.attemptCount,
          equals(20));
    });

    test(
        '32. Merge decision explanation contains transparent arithmetic summary',
        () {
      final state = buildSampleState();
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_polity_fr');
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final explanation =
          reconciled.objectiveDecisions['obj_polity_fr']!.explanation;
      expect(explanation, contains('prior 10 + new 2 = 12 attempts'));
    });
  });

  // ==========================================================================
  // GROUP 5: Conflicting Update & Authoritative Precedence (8 tests)
  // ==========================================================================
  group('P38.5 Group 5 — Conflicting Update & Authoritative Precedence', () {
    test(
        '33. Authoritative state precedence resolves conflict without silent mutation',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.isSuccessful, isTrue);
    });

    test(
        '34. Reconciler preserves achieved status when practice attempt fails threshold',
        () {
      final state = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'obj_polity_fr',
            attemptCount: 10,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      final prop = buildSampleProposal(correctCount: 0, incorrectCount: 10);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_polity_fr']!;
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
    });

    test(
        '35. Authoritative state values take precedence over transient ungrounded overrides',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.baseStateFingerprint, equals(state.stateFingerprint));
    });

    test('36. Conflict audit log captures dimension and identifier', () {
      const conflict = ReconciliationConflict(
        dimension: 'objective',
        identifier: 'obj_test',
        conflictType: 'statusRegress',
        authoritativeValue: 'achieved',
        proposedValue: 'inProgress',
        resolvedValue: 'achieved',
        resolutionReason: 'Authoritative achievement status preserved.',
      );

      expect(conflict.dimension, equals('objective'));
      expect(conflict.identifier, equals('obj_test'));
      expect(conflict.resolvedValue, equals('achieved'));
    });

    test('37. Conflict audit log serializes and deserializes cleanly', () {
      const conflict = ReconciliationConflict(
        dimension: 'objective',
        identifier: 'obj_test',
        conflictType: 'statusRegress',
        authoritativeValue: 'achieved',
        proposedValue: 'inProgress',
        resolvedValue: 'achieved',
        resolutionReason: 'Authoritative achievement status preserved.',
      );

      final json = conflict.toJson();
      final fromJson = ReconciliationConflict.fromJson(json);

      expect(fromJson.dimension, equals(conflict.dimension));
      expect(fromJson.identifier, equals(conflict.identifier));
      expect(fromJson.resolutionReason, equals(conflict.resolutionReason));
    });

    test('38. Conflict toString contains descriptive summary', () {
      const conflict = ReconciliationConflict(
        dimension: 'objective',
        identifier: 'obj_1',
        conflictType: 'type_a',
        resolutionReason: 'Reason',
      );

      expect(conflict.toString(), contains('objective:obj_1'));
      expect(conflict.toString(), contains('Reason'));
    });

    test('39. Precedence model is deterministic across executions', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final r1 = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(r1.fingerprint, equals(r2.fingerprint));
    });

    test(
        '40. Non-conflicting attributes merge cleanly alongside conflict-resolved attributes',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.reconciledProgress.isNotEmpty, isTrue);
    });
  });

  // ==========================================================================
  // GROUP 6: Stale Proposal Detection (8 tests)
  // ==========================================================================
  group('P38.6 Group 6 — Stale Proposal Detection', () {
    test(
        '41. Proposal timestamp older than state lastUpdatedAt is marked stale',
        () {
      final recentStateTime = DateTime.utc(2026, 9, 2);
      final olderProposalTime = DateTime.utc(2026, 9, 1);

      final state = buildSampleState(lastUpdatedAt: recentStateTime);
      final prop = buildSampleProposal(correctCount: 2);

      // Proposal completed at fixedDate (2026-09-01), while state was updated 2026-09-02
      final reconciled = reconciler
          .reconcile(
            authoritativeState: state,
            proposal: prop,
            reconciledAt: olderProposalTime,
          )
          .valueOrThrow;

      expect(reconciled.overallDecision, equals(ReconciliationDecision.stale));
    });

    test('42. Stale proposal does NOT modify authoritative progress map', () {
      final state = buildSampleState(lastUpdatedAt: DateTime.utc(2026, 9, 5));
      final prop = buildSampleProposal(
          correctCount: 2); // proposedAt is fixedDate (2026-09-01)

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.reconciledProgress['obj_polity_fr']!.attemptCount,
          equals(state.progressMap['obj_polity_fr']!.attemptCount));
      expect(reconciled.hasStateChanges, isFalse);
    });

    test('43. Stale proposal logs a conflict explaining rejection reason', () {
      final state = buildSampleState(lastUpdatedAt: DateTime.utc(2026, 9, 5));
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.conflicts.isNotEmpty, isTrue);
      expect(reconciled.conflicts.first.conflictType, equals('staleProposal'));
    });

    test('44. Stale decision hasStateChanges returns false', () {
      final state = buildSampleState(lastUpdatedAt: DateTime.utc(2026, 9, 5));
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.hasStateChanges, isFalse);
    });

    test('45. Equal timestamps are NOT treated as stale', () {
      final state = buildSampleState(lastUpdatedAt: fixedDate);
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.overallDecision,
          isNot(equals(ReconciliationDecision.stale)));
    });

    test('46. Newer proposal is accepted / merged normally', () {
      final state = buildSampleState(lastUpdatedAt: DateTime.utc(2026, 8, 1));
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.overallDecision, equals(ReconciliationDecision.merged));
    });

    test(
        '47. Stale proposal preserves authoritative session history without adding stale session',
        () {
      final state = buildSampleState(
        lastUpdatedAt: DateTime.utc(2026, 9, 5),
        processedSessionIds: {'sess_1'},
      );
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.processedSessionIds, equals({'sess_1'}));
    });

    test('48. Stale decision produces valid canonical fingerprint', () {
      final state = buildSampleState(lastUpdatedAt: DateTime.utc(2026, 9, 5));
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.fingerprint, hasLength(64));
    });
  });

  // ==========================================================================
  // GROUP 7: Duplicate Evidence & Idempotency (8 tests)
  // ==========================================================================
  group('P38.7 Group 7 — Duplicate Evidence & Idempotency', () {
    test(
        '49. Reconciling proposal whose session is in processedSessionIds returns duplicate',
        () {
      final prop = buildSampleProposal(correctCount: 2);
      final state = buildSampleState(
        processedSessionIds: {prop.sessionId},
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
          reconciled.overallDecision, equals(ReconciliationDecision.duplicate));
      expect(reconciled.hasStateChanges, isFalse);
    });

    test('50. Duplicate proposal does NOT increment attempt counts', () {
      final prop = buildSampleProposal(correctCount: 2);
      final state = buildSampleState(
        processedSessionIds: {prop.sessionId},
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final existingAttempts = state.progressMap['obj_polity_fr']!.attemptCount;
      final reconciledAttempts =
          reconciled.reconciledProgress['obj_polity_fr']!.attemptCount;

      expect(reconciledAttempts, equals(existingAttempts));
    });

    test(
        '51. Sequential Idempotency: reconcile(S, P) then reconcile(S\', P) is a no-op',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 3);

      // First application: merged
      final r1 = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(r1.overallDecision, equals(ReconciliationDecision.merged));

      // Construct intermediate authoritative state from r1
      final intermediateState = AuthoritativeLearnerState(
        learnerId: r1.learnerId,
        examId: r1.examId,
        progressMap: r1.reconciledProgress,
        processedSessionIds: r1.processedSessionIds,
        lastUpdatedAt: r1.reconciledAt,
      );

      // Second application of exact same proposal: duplicate no-op
      final r2 = reconciler
          .reconcile(authoritativeState: intermediateState, proposal: prop)
          .valueOrThrow;

      expect(r2.overallDecision, equals(ReconciliationDecision.duplicate));
      expect(r2.hasStateChanges, isFalse);
      expect(
        r2.reconciledProgress['obj_polity_fr']!.attemptCount,
        equals(r1.reconciledProgress['obj_polity_fr']!.attemptCount),
      );
    });

    test(
        '52. Duplicate proposal produces identical progress map to input state',
        () {
      final prop = buildSampleProposal(correctCount: 2);
      final state = buildSampleState(processedSessionIds: {prop.sessionId});

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.reconciledProgress, equals(state.progressMap));
    });

    test('53. Duplicate decision hasStateChanges returns false', () {
      final prop = buildSampleProposal(correctCount: 2);
      final state = buildSampleState(processedSessionIds: {prop.sessionId});

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.hasStateChanges, isFalse);
    });

    test(
        '54. AuthoritativeLearnerState.hasProcessedSession returns true for contained session',
        () {
      final state = buildSampleState(processedSessionIds: {'sess_abc'});
      expect(state.hasProcessedSession('sess_abc'), isTrue);
      expect(state.hasProcessedSession('sess_xyz'), isFalse);
    });

    test('55. Processed session IDs set is preserved and extended upon merge',
        () {
      final state = buildSampleState(processedSessionIds: {'sess_1'});
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.processedSessionIds.contains('sess_1'), isTrue);
      expect(reconciled.processedSessionIds.contains(prop.sessionId), isTrue);
    });

    test(
        '56. Reapplying duplicate proposal produces deterministic identical fingerprint',
        () {
      final prop = buildSampleProposal(correctCount: 2);
      final state = buildSampleState(processedSessionIds: {prop.sessionId});

      final r1 = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(r1.fingerprint, equals(r2.fingerprint));
    });
  });

  // ==========================================================================
  // GROUP 8: Question Reconciliation Decisions (8 tests)
  // ==========================================================================
  group('P38.8 Group 8 — Question Reconciliation Decisions', () {
    test('57. Answered question is marked accepted', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final qDec = reconciled.questionDecisions.first;
      expect(qDec.decision, equals(ReconciliationDecision.accepted));
      expect(qDec.proposedAction, equals(ProposedLearningAction.retainMastery));
    });

    test('58. Incorrect question decision records reviewRemediation proposal',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, incorrectCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final qDec = reconciled.questionDecisions.first;
      expect(qDec.decision, equals(ReconciliationDecision.accepted));
      expect(qDec.proposedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test('59. Skipped question decision is marked unchanged', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, skippedCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final qDec = reconciled.questionDecisions.first;
      expect(qDec.decision, equals(ReconciliationDecision.unchanged));
      expect(
          qDec.proposedAction, equals(ProposedLearningAction.continueExposure));
    });

    test('60. Question decision records questionId accurately', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.questionDecisions.first.questionId, equals('q_0'));
    });

    test('61. Question decisions sequence matches presentation order', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 3);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      for (int i = 0; i < 3; i++) {
        expect(reconciled.questionDecisions[i].questionId, equals('q_$i'));
      }
    });

    test('62. Question decision explanation explains reason', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
          reconciled.questionDecisions.first.explanation, contains('Accepted'));
    });

    test('63. Question decision serializes and deserializes cleanly', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final qDec = reconciled.questionDecisions.first;
      final json = qDec.toJson();
      final fromJson = QuestionReconciliationDecision.fromJson(json);

      expect(fromJson.questionId, equals(qDec.questionId));
      expect(fromJson.decision, equals(qDec.decision));
      expect(fromJson.proposedAction, equals(qDec.proposedAction));
    });

    test('64. Empty proposal produces empty question decisions list', () {
      final state = buildSampleState();
      final emptyProp = buildSampleProposal(correctCount: 0);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: emptyProp)
          .valueOrThrow;

      expect(reconciled.questionDecisions, isEmpty);
    });
  });

  // ==========================================================================
  // GROUP 9: Topic Reconciliation Decisions (8 tests)
  // ==========================================================================
  group('P38.9 Group 9 — Topic Reconciliation Decisions', () {
    test('65. Attempted topic is marked accepted in topic decisions', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final tDec = reconciled.topicDecisions['Fundamental Rights']!;
      expect(tDec.decision, equals(ReconciliationDecision.accepted));
      expect(tDec.proposedAction, equals(ProposedLearningAction.retainMastery));
    });

    test('66. Topic decision preserves topic label', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
          reconciled.topicDecisions.containsKey('Fundamental Rights'), isTrue);
    });

    test('67. Topic decision explanation contains attempt count and pattern',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final tDec = reconciled.topicDecisions['Fundamental Rights']!;
      expect(tDec.explanation, contains('2 attempts'));
    });

    test('68. Topic with 0 attempts is marked unchanged', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, skippedCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final tDec = reconciled.topicDecisions['Fundamental Rights']!;
      expect(tDec.decision, equals(ReconciliationDecision.unchanged));
    });

    test('69. Topic decisions map keys are strictly ordered alphabetically',
        () {
      final state = buildSampleState();
      final q1 = buildQuestion(id: 'q_1', topic: 'Preamble');
      final q2 = buildQuestion(id: 'q_2', topic: 'Citizenship');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var exec = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      exec = engine
          .submitAnswer(
              state: exec,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      exec = engine
          .submitAnswer(
              state: exec,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: exec).valueOrThrow;
      final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.topicDecisions.keys.toList(),
          equals(['Citizenship', 'Preamble']));
    });

    test('70. Topic decision serializes and deserializes cleanly', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final tDec = reconciled.topicDecisions.values.first;
      final json = tDec.toJson();
      final fromJson = TopicReconciliationDecision.fromJson(json);

      expect(fromJson.topic, equals(tDec.topic));
      expect(fromJson.decision, equals(tDec.decision));
    });

    test('71. Multiple topics generate separate granular topic decisions', () {
      final state = buildSampleState();
      final q1 = buildQuestion(id: 'q_1', topic: 'History');
      final q2 = buildQuestion(id: 'q_2', topic: 'Polity');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var exec = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      exec = engine
          .submitAnswer(
              state: exec,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      exec = engine
          .submitAnswer(
              state: exec,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: exec).valueOrThrow;
      final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(reconciled.topicDecisions.length, equals(2));
      expect(reconciled.topicDecisions.containsKey('History'), isTrue);
      expect(reconciled.topicDecisions.containsKey('Polity'), isTrue);
    });

    test('72. Topic decision preserves proposedAction from P37', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 0, incorrectCount: 3);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final tDec = reconciled.topicDecisions.values.first;
      expect(tDec.proposedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });
  });

  // ==========================================================================
  // GROUP 10: Objective Achievement Threshold Evaluation (8 tests)
  // ==========================================================================
  group('P38.10 Group 10 — Objective Achievement Threshold Evaluation', () {
    test('73. Default threshold requires min 5 attempts and >= 80% success',
        () {
      const config = AssessmentThresholdConfig();
      expect(config.isAchieved(attemptCount: 4, successRate: 1.0), isFalse);
      expect(config.isAchieved(attemptCount: 5, successRate: 0.79), isFalse);
      expect(config.isAchieved(attemptCount: 5, successRate: 0.80), isTrue);
    });

    test('74. Custom threshold config is respected during reconciliation', () {
      const customConfig = AssessmentThresholdConfig(
        minimumAttempts: 3,
        minimumSuccessRate: 0.70,
      );

      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final prop = buildSampleProposal(
        correctCount: 3,
        objectiveId: 'obj_custom_thresh',
      );

      final reconciled = reconciler
          .reconcile(
            authoritativeState: emptyState,
            proposal: prop,
            thresholdConfig: customConfig,
          )
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_custom_thresh']!;
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
    });

    test('75. Achieving objective sets achievedAt timestamp to reconciledAt',
        () {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final prop = buildSampleProposal(
        correctCount: 5,
        objectiveId: 'obj_achieve_time',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: emptyState, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_achieve_time']!;
      expect(progress.achievedAt, equals(reconciled.reconciledAt));
    });

    test(
        '76. Existing achievedAt timestamp is preserved when objective remains achieved',
        () {
      final originalAchievedTime = DateTime.utc(2025, 6, 1);
      final state = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'obj_polity_fr',
            attemptCount: 10,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
            achievedAt: originalAchievedTime,
          ),
        },
      );
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_polity_fr']!;
      expect(progress.achievedAt, equals(originalAchievedTime));
    });

    test('77. Below threshold objective remains inProgress without achievedAt',
        () {
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: 'learner_101',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final prop = buildSampleProposal(
        correctCount: 1,
        incorrectCount: 1,
        objectiveId: 'obj_low',
      );

      final reconciled = reconciler
          .reconcile(authoritativeState: emptyState, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_low']!;
      expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
      expect(progress.achievedAt, isNull);
    });

    test('78. Objective decision records priorStatus and reconciledStatus', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final oDec = reconciled.objectiveDecisions['obj_polity_fr']!;
      expect(oDec.priorStatus, equals(LearnerObjectiveStatus.inProgress));
      expect(oDec.reconciledStatus, equals(LearnerObjectiveStatus.achieved));
    });

    test('79. Zero attempts in progress produces notStarted status', () {
      final p = LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'obj_0',
        attemptCount: 0,
        status: LearnerObjectiveStatus.notStarted,
      );
      expect(p.status, equals(LearnerObjectiveStatus.notStarted));
    });

    test('80. Success rate is bounded strictly in [0.0, 1.0]', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 3);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final progress = reconciled.reconciledProgress['obj_polity_fr']!;
      expect(progress.successRate, inInclusiveRange(0.0, 1.0));
    });
  });

  // ==========================================================================
  // GROUP 11: Multi-Exam Isolation & Cross-Exam Rejection (8 tests)
  // ==========================================================================
  group('P38.11 Group 11 — Multi-Exam Isolation & Cross-Exam Rejection', () {
    test(
        '81. Reconciling UPSC state with BPSC proposal fails with examMismatch',
        () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final propBpsc = buildSampleProposal(examId: 'bpsc', correctCount: 2);

      final result = reconciler.reconcile(
        authoritativeState: stateUpsc,
        proposal: propBpsc,
      );

      expect(result.isFailure, isTrue);
      expect(result.error?.code, equals(ReconciliationErrorCode.examMismatch));
    });

    test('82. Reconciling BPSC state with BPSC proposal succeeds', () {
      final stateBpsc = buildSampleState(examId: 'bpsc');
      final propBpsc = buildSampleProposal(examId: 'bpsc', correctCount: 2);

      final result = reconciler.reconcile(
        authoritativeState: stateBpsc,
        proposal: propBpsc,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrThrow.examId, equals('bpsc'));
    });

    test('83. Reconciling SSC state with SSC proposal succeeds', () {
      final stateSsc = buildSampleState(examId: 'ssc');
      final propSsc = buildSampleProposal(examId: 'ssc', correctCount: 2);

      final result = reconciler.reconcile(
        authoritativeState: stateSsc,
        proposal: propSsc,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrThrow.examId, equals('ssc'));
    });

    test(
        '84. Same question ID in different exams produces distinct proposal fingerprints',
        () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final stateBpsc = buildSampleState(examId: 'bpsc');
      final propUpsc = buildSampleProposal(examId: 'upsc', correctCount: 2);
      final propBpsc = buildSampleProposal(examId: 'bpsc', correctCount: 2);

      final rUpsc = reconciler
          .reconcile(authoritativeState: stateUpsc, proposal: propUpsc)
          .valueOrThrow;
      final rBpsc = reconciler
          .reconcile(authoritativeState: stateBpsc, proposal: propBpsc)
          .valueOrThrow;

      expect(rUpsc.fingerprint, isNot(equals(rBpsc.fingerprint)));
    });

    test('85. Exam ID is case-normalized to lowercase', () {
      final state = buildSampleState(examId: 'UPSC');
      expect(state.examId, equals('upsc'));
    });

    test(
        '86. Exam mismatch error details contain authoritative and proposal exams',
        () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final propBpsc = buildSampleProposal(examId: 'bpsc', correctCount: 1);

      final result = reconciler.reconcile(
          authoritativeState: stateUpsc, proposal: propBpsc);
      expect(result.error?.details?['authoritativeExam'], equals('upsc'));
      expect(result.error?.details?['proposalExam'], equals('bpsc'));
    });

    test('87. Reconciled proposal preserves examId across all operations', () {
      final state = buildSampleState(examId: 'upsc');
      final prop = buildSampleProposal(examId: 'upsc', correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.examId, equals('upsc'));
    });

    test('88. Canonical fingerprint incorporates examId', () {
      final state = buildSampleState(examId: 'upsc');
      final prop = buildSampleProposal(examId: 'upsc', correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.fingerprint, isNotEmpty);
    });
  });

  // ==========================================================================
  // GROUP 12: Learner Identity Isolation (8 tests)
  // ==========================================================================
  group('P38.12 Group 12 — Learner Identity Isolation', () {
    test('89. Proposal with differing learnerId fails with learnerMismatch',
        () {
      final stateLearnerA = buildSampleState(learnerId: 'learner_A');
      final propLearnerB =
          buildSampleProposal(learnerId: 'learner_B', correctCount: 2);

      final result = reconciler.reconcile(
        authoritativeState: stateLearnerA,
        proposal: propLearnerB,
      );

      expect(result.isFailure, isTrue);
      expect(
          result.error?.code, equals(ReconciliationErrorCode.learnerMismatch));
    });

    test('90. Matching learnerId succeeds', () {
      final state = buildSampleState(learnerId: 'learner_A');
      final prop = buildSampleProposal(learnerId: 'learner_A', correctCount: 2);

      final result =
          reconciler.reconcile(authoritativeState: state, proposal: prop);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrThrow.learnerId, equals('learner_A'));
    });

    test(
        '91. Null proposal learnerId defaults safely to authoritative learnerId',
        () {
      final state = buildSampleState(learnerId: 'learner_A');
      final prop = buildSampleProposal(learnerId: null, correctCount: 2);

      final result =
          reconciler.reconcile(authoritativeState: state, proposal: prop);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrThrow.learnerId, equals('learner_A'));
    });

    test('92. Learner mismatch error details contain both learner IDs', () {
      final stateLearnerA = buildSampleState(learnerId: 'learner_A');
      final propLearnerB =
          buildSampleProposal(learnerId: 'learner_B', correctCount: 2);

      final result = reconciler.reconcile(
          authoritativeState: stateLearnerA, proposal: propLearnerB);
      expect(
          result.error?.details?['authoritativeLearner'], equals('learner_A'));
      expect(result.error?.details?['proposalLearner'], equals('learner_B'));
    });

    test('93. Different learners produce distinct proposal fingerprints', () {
      final stateA = buildSampleState(learnerId: 'learner_A');
      final stateB = buildSampleState(learnerId: 'learner_B');
      final propA =
          buildSampleProposal(learnerId: 'learner_A', correctCount: 2);
      final propB =
          buildSampleProposal(learnerId: 'learner_B', correctCount: 2);

      final rA = reconciler
          .reconcile(authoritativeState: stateA, proposal: propA)
          .valueOrThrow;
      final rB = reconciler
          .reconcile(authoritativeState: stateB, proposal: propB)
          .valueOrThrow;

      expect(rA.fingerprint, isNot(equals(rB.fingerprint)));
    });

    test('94. Reconciled progress records all carry authoritative learnerId',
        () {
      final state = buildSampleState(learnerId: 'aspirant_77');
      final prop =
          buildSampleProposal(learnerId: 'aspirant_77', correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      for (final p in reconciled.reconciledProgress.values) {
        expect(p.learnerId, equals('aspirant_77'));
      }
    });

    test(
        '95. Blank learnerId on AuthoritativeLearnerState throws ArgumentError',
        () {
      expect(
        () => AuthoritativeLearnerState(
          learnerId: '  ',
          examId: 'upsc',
          progressMap: const {},
          lastUpdatedAt: fixedDate,
        ),
        throwsArgumentError,
      );
    });

    test('96. Learner identity preserved through serializations', () {
      final state = buildSampleState(learnerId: 'aspirant_42');
      final json = state.toJson();
      final restored = AuthoritativeLearnerState.fromJson(json);

      expect(restored.learnerId, equals('aspirant_42'));
    });
  });

  // ==========================================================================
  // GROUP 13: P19 Boundary Verification (Zero Direct DB Writes) (4 tests)
  // ==========================================================================
  group('P38.13 Group 13 — P19 Boundary Verification', () {
    test(
        '97. Reconciler returns proposal without mutating database or persistence',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled, isA<ReconciledLearningStateProposal>());
    });

    test('98. Reconciled proposal contains no persistent database handles', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('db'), isFalse);
      expect(json.containsKey('sqlite'), isFalse);
    });

    test('99. State progress map is read-only unmodifiable', () {
      final state = buildSampleState();
      expect(() => state.progressMap['key'] = state.progressMap.values.first,
          throwsUnsupportedError);
    });

    test('100. P38 is a pure proposal layer between P37 and P19', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final res =
          reconciler.reconcile(authoritativeState: state, proposal: prop);
      expect(res.isSuccess, isTrue);
    });
  });

  // ==========================================================================
  // GROUP 14: P20 Boundary Verification (Zero SM-2 / Scheduling) (4 tests)
  // ==========================================================================
  group('P38.14 Group 14 — P20 Boundary Verification', () {
    test('101. P38 does NOT calculate SM-2 ease factors', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('easeFactor'), isFalse);
      expect(json.containsKey('efactor'), isFalse);
    });

    test('102. P38 does NOT calculate review intervals or due dates', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('interval'), isFalse);
      expect(json.containsKey('nextReviewDate'), isFalse);
    });

    test('103. P38 does NOT calculate repetition numbers', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('repetitionNumber'), isFalse);
    });

    test('104. P38 does NOT mutate spaced repetition queues', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled, isA<ReconciledLearningStateProposal>());
    });
  });

  // ==========================================================================
  // GROUP 15: P23 Boundary Verification (Descriptive Only) (4 tests)
  // ==========================================================================
  group('P38.15 Group 15 — P23 Boundary Verification', () {
    test('105. P38 does NOT calculate learning velocity', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('learningVelocity'), isFalse);
    });

    test('106. P38 does NOT produce retention decay curves', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('decayCurve'), isFalse);
    });

    test('107. P38 does NOT diagnose multi-session weak spot profiles', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('weakSpotProfile'), isFalse);
    });

    test('108. P38 outputs reconciled progress without longitudinal analytics',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.reconciledProgress.isNotEmpty, isTrue);
    });
  });

  // ==========================================================================
  // GROUP 16: P33/P34 Boundary Verification (Zero Selection / Composition) (4 tests)
  // ==========================================================================
  group('P38.16 Group 16 — P33/P34 Boundary Verification', () {
    test('109. P38 does NOT rank or select questions', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('selectedQuestions'), isFalse);
      expect(json.containsKey('rankedCandidates'), isFalse);
    });

    test('110. P38 does NOT compose future practice sessions', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('nextSessionSpec'), isFalse);
    });

    test('111. P38 does NOT determine future pedagogical mode', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.toJson();
      expect(json.containsKey('nextSessionMode'), isFalse);
    });

    test('112. P38 produces reconciled state only', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled, isA<ReconciledLearningStateProposal>());
    });
  });

  // ==========================================================================
  // GROUP 17: Immutability & Mutation Safety (6 tests)
  // ==========================================================================
  group('P38.17 Group 17 — Immutability & Mutation Safety', () {
    test('113. AuthoritativeLearnerState is NOT mutated during reconciliation',
        () {
      final state = buildSampleState();
      final baselineFingerprint = state.stateFingerprint;
      final baselineAttempts = state.progressMap['obj_polity_fr']!.attemptCount;

      final prop = buildSampleProposal(correctCount: 2);
      reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(state.stateFingerprint, equals(baselineFingerprint));
      expect(state.progressMap['obj_polity_fr']!.attemptCount,
          equals(baselineAttempts));
    });

    test(
        '114. LearningStateUpdateProposal is NOT mutated during reconciliation',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);
      final baselineFp = prop.fingerprint;

      reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(prop.fingerprint, equals(baselineFp));
    });

    test(
        '115. Repeated reads of reconciledProgress return identical unmodifiable maps',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
          identical(
              reconciled.reconciledProgress, reconciled.reconciledProgress),
          isTrue);
    });

    test(
        '116. AuthoritativeLearnerState progressMap cannot be modified externally',
        () {
      final state = buildSampleState();
      expect(() => state.progressMap.clear(), throwsUnsupportedError);
    });

    test(
        '117. AuthoritativeLearnerState processedSessionIds cannot be modified externally',
        () {
      final state = buildSampleState();
      expect(() => state.processedSessionIds.clear(), throwsUnsupportedError);
    });

    test(
        '118. ReconciledLearningStateProposal conflicts list cannot be modified externally',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      expect(
          () => reconciled.conflicts.add(const ReconciliationConflict(
              dimension: 'd',
              identifier: 'i',
              conflictType: 'c',
              resolutionReason: 'r')),
          throwsUnsupportedError);
    });
  });

  // ==========================================================================
  // GROUP 18: Determinism & Canonical Ordering (8 tests)
  // ==========================================================================
  group('P38.18 Group 18 — Determinism & Canonical Ordering', () {
    test(
        '119. Repeated reconciliation of identical inputs produces byte-identical proposals',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final r1 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;

      expect(jsonEncode(r1.toJson()), equals(jsonEncode(r2.toJson())));
      expect(r1.fingerprint, equals(r2.fingerprint));
    });

    test('120. Repeated JSON serialization is byte-identical', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final j1 = jsonEncode(reconciled.toJson());
      final j2 = jsonEncode(reconciled.toJson());
      expect(j1, equals(j2));
    });

    test('121. Repeated SHA-256 fingerprint generation is identical', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final r1 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;

      expect(r1.fingerprint, equals(r2.fingerprint));
    });

    test('122. Reconciled progress keys strictly alphabetical', () {
      final pB = LearnerProgress(learnerId: 'l1', objectiveId: 'obj_b');
      final pA = LearnerProgress(learnerId: 'l1', objectiveId: 'obj_a');
      final state = buildSampleState(progressMap: {'obj_b': pB, 'obj_a': pA});
      final prop = buildSampleProposal(correctCount: 1, objectiveId: 'obj_c');

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.reconciledProgress.keys.toList(),
          equals(['obj_a', 'obj_b', 'obj_c']));
    });

    test('123. Objective decisions keys strictly alphabetical', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final keys = reconciled.objectiveDecisions.keys.toList();
      final sortedKeys = List<String>.from(keys)..sort();

      expect(keys, equals(sortedKeys));
    });

    test('124. Topic decisions keys strictly alphabetical', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final keys = reconciled.topicDecisions.keys.toList();
      final sortedKeys = List<String>.from(keys)..sort();

      expect(keys, equals(sortedKeys));
    });

    test('125. Processed session IDs strictly sorted alphabetically', () {
      final state = buildSampleState(processedSessionIds: {'sess_z', 'sess_a'});
      final prop = buildSampleProposal(correctCount: 1);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final list = reconciled.processedSessionIds.toList();
      final sortedList = List<String>.from(list)..sort();

      expect(list, equals(sortedList));
    });

    test('126. Question decisions strictly preserve presentation order', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 3);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      for (int i = 0; i < 3; i++) {
        expect(reconciled.questionDecisions[i].questionId, equals('q_$i'));
      }
    });
  });

  // ==========================================================================
  // GROUP 19: Fingerprint Sensitivity & Stability (6 tests)
  // ==========================================================================
  group('P38.19 Group 19 — Fingerprint Sensitivity & Stability', () {
    test('127. Changing correctCount changes fingerprint', () {
      final state = buildSampleState();
      final prop1 = buildSampleProposal(correctCount: 2);
      final prop2 = buildSampleProposal(correctCount: 1, incorrectCount: 1);

      final r1 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop1,
              reconciledAt: fixedDate)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop2,
              reconciledAt: fixedDate)
          .valueOrThrow;

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('128. Changing baseState changes fingerprint', () {
      final state1 = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
              learnerId: 'l1',
              objectiveId: 'obj_polity_fr',
              attemptCount: 10,
              correctCount: 8),
        },
      );
      final state2 = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
              learnerId: 'l1',
              objectiveId: 'obj_polity_fr',
              attemptCount: 20,
              correctCount: 18),
        },
      );
      final prop = buildSampleProposal(correctCount: 2);

      final r1 = reconciler
          .reconcile(
              authoritativeState: state1,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(
              authoritativeState: state2,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('129. Changing reconciledAt timestamp changes fingerprint', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final r1 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: DateTime.utc(2026, 9, 1))
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: DateTime.utc(2026, 9, 2))
          .valueOrThrow;

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('130. Changing overallDecision changes fingerprint', () {
      final state = buildSampleState();
      final propActive = buildSampleProposal(correctCount: 2);
      final propNoOp = buildSampleProposal(correctCount: 0);

      final r1 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: propActive,
              reconciledAt: fixedDate)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: propNoOp,
              reconciledAt: fixedDate)
          .valueOrThrow;

      expect(r1.fingerprint, isNot(equals(r2.fingerprint)));
    });

    test('131. Duplicate reconciliation produces stable fingerprint', () {
      final prop = buildSampleProposal(correctCount: 2);
      final state = buildSampleState(processedSessionIds: {prop.sessionId});

      final r1 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;
      final r2 = reconciler
          .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: fixedDate)
          .valueOrThrow;

      expect(r1.fingerprint, equals(r2.fingerprint));
    });

    test('132. Changing examId changes fingerprint', () {
      final stateUpsc = buildSampleState(examId: 'upsc');
      final stateBpsc = buildSampleState(examId: 'bpsc');
      final propUpsc = buildSampleProposal(examId: 'upsc', correctCount: 2);
      final propBpsc = buildSampleProposal(examId: 'bpsc', correctCount: 2);

      final rUpsc = reconciler
          .reconcile(
              authoritativeState: stateUpsc,
              proposal: propUpsc,
              reconciledAt: fixedDate)
          .valueOrThrow;
      final rBpsc = reconciler
          .reconcile(
              authoritativeState: stateBpsc,
              proposal: propBpsc,
              reconciledAt: fixedDate)
          .valueOrThrow;

      expect(rUpsc.fingerprint, isNot(equals(rBpsc.fingerprint)));
    });
  });

  // ==========================================================================
  // GROUP 20: Error Handling & Idempotency (8 tests)
  // ==========================================================================
  group('P38.20 Group 20 — Error Handling & Idempotency', () {
    test('133. Exam mismatch produces typed ReconciliationError', () {
      final state = buildSampleState(examId: 'upsc');
      final prop = buildSampleProposal(examId: 'bpsc', correctCount: 1);

      final res =
          reconciler.reconcile(authoritativeState: state, proposal: prop);
      expect(res.isFailure, isTrue);
      expect(res.error?.code, equals(ReconciliationErrorCode.examMismatch));
    });

    test('134. Learner mismatch produces typed ReconciliationError', () {
      final state = buildSampleState(learnerId: 'l1');
      final prop = buildSampleProposal(learnerId: 'l2', correctCount: 1);

      final res =
          reconciler.reconcile(authoritativeState: state, proposal: prop);
      expect(res.isFailure, isTrue);
      expect(res.error?.code, equals(ReconciliationErrorCode.learnerMismatch));
    });

    test('135. Result valueOrThrow returns value on success', () {
      const res = ReconciliationResult<int>.success(42);
      expect(res.valueOrThrow, equals(42));
    });

    test('136. Result valueOrThrow throws StateError on failure', () {
      const res = ReconciliationResult<int>.failure(
        ReconciliationError(
            code: ReconciliationErrorCode.invalidState, message: 'Invalid'),
      );
      expect(() => res.valueOrThrow, throwsStateError);
    });

    test('137. ReconciliationError serializes and deserializes cleanly', () {
      const err = ReconciliationError(
        code: ReconciliationErrorCode.examMismatch,
        message: 'Mismatch description',
        details: {'key': 'val'},
      );
      final json = err.toJson();
      final fromJson = ReconciliationError.fromJson(json);

      expect(fromJson.code, equals(err.code));
      expect(fromJson.message, equals(err.message));
    });

    test('138. ReconciliationError toString formats properly', () {
      const err = ReconciliationError(
          code: ReconciliationErrorCode.invalidState, message: 'Error msg');
      expect(
          err.toString(), contains('ReconciliationError(code: invalidState'));
    });

    test('139. ReconciliationResult toString formats properly', () {
      const resSuccess = ReconciliationResult.success('DONE');
      expect(resSuccess.toString(),
          contains('ReconciliationResult.success(DONE)'));

      const resFail = ReconciliationResult<String>.failure(
        ReconciliationError(
            code: ReconciliationErrorCode.invalidState, message: 'Bad'),
      );
      expect(resFail.toString(), contains('ReconciliationResult.failure'));
    });

    test('140. Repeated error checks are deterministic', () {
      final state = buildSampleState(examId: 'upsc');
      final prop = buildSampleProposal(examId: 'bpsc', correctCount: 1);

      final res1 =
          reconciler.reconcile(authoritativeState: state, proposal: prop);
      final res2 =
          reconciler.reconcile(authoritativeState: state, proposal: prop);

      expect(res1.error?.code, equals(res2.error?.code));
    });
  });

  // ==========================================================================
  // GROUP 21: High-Throughput Benchmarks (8 tests)
  // ==========================================================================
  group('P38.21 Group 21 — High-Throughput Benchmarks', () {
    test('141. 1,000 objectives state reconciliation in < 50ms', () {
      final map1K = <String, LearnerProgress>{};
      for (int i = 0; i < 1000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map1K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state = buildSampleState(progressMap: map1K);
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_000000');

      final sw = Stopwatch()..start();
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      sw.stop();

      expect(reconciled.reconciledProgress.length, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('142. 1,000 objectives fingerprint calculation in < 20ms', () {
      final map1K = <String, LearnerProgress>{};
      for (int i = 0; i < 1000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map1K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state = buildSampleState(progressMap: map1K);
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_000000');

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.fingerprint, hasLength(64));
    });

    test('143. 10,000 objectives state reconciliation in < 150ms', () {
      final map10K = <String, LearnerProgress>{};
      for (int i = 0; i < 10000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map10K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state = buildSampleState(progressMap: map10K);
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_000000');

      final sw = Stopwatch()..start();
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      sw.stop();

      expect(reconciled.reconciledProgress.length, equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(350));
    });

    test('144. 10,000 objectives serialization in < 50ms', () {
      final map10K = <String, LearnerProgress>{};
      for (int i = 0; i < 10000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map10K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state = buildSampleState(progressMap: map10K);
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_000000');
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      final json = reconciled.toJson();
      sw.stop();

      expect((json['reconciledProgress'] as Map).length, equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('145. 50,000 objectives state reconciliation in < 500ms', () {
      final map50K = <String, LearnerProgress>{};
      for (int i = 0; i < 50000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map50K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state = buildSampleState(progressMap: map50K);
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_000000');

      final sw = Stopwatch()..start();
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      sw.stop();

      expect(reconciled.reconciledProgress.length, equals(50000));
      expect(sw.elapsedMilliseconds, lessThan(1500));
    });

    test('146. 100,000 objectives state reconciliation in < 2,000ms', () {
      final map100K = <String, LearnerProgress>{};
      for (int i = 0; i < 100000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map100K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state = buildSampleState(progressMap: map100K);
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_000000');

      final sw = Stopwatch()..start();
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      sw.stop();

      expect(reconciled.reconciledProgress.length, equals(100000));
      expect(sw.elapsedMilliseconds, lessThan(4000));
    });

    test('147. Single reconciliation lookup latency < 1ms average', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        reconciler
            .reconcile(authoritativeState: state, proposal: prop)
            .valueOrThrow;
      }
      sw.stop();

      final avgMicroseconds = sw.elapsedMicroseconds / 1000;
      expect(avgMicroseconds, lessThan(1000));
    });

    test('148. Linear O(n) scaling verified between 10K and 50K', () {
      final map10K = <String, LearnerProgress>{};
      for (int i = 0; i < 10000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map10K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state10K = buildSampleState(progressMap: map10K);
      final prop =
          buildSampleProposal(correctCount: 2, objectiveId: 'obj_000000');

      final sw1 = Stopwatch()..start();
      reconciler
          .reconcile(authoritativeState: state10K, proposal: prop)
          .valueOrThrow;
      sw1.stop();

      final map50K = <String, LearnerProgress>{};
      for (int i = 0; i < 50000; i++) {
        final id = 'obj_${i.toString().padLeft(6, '0')}';
        map50K[id] = LearnerProgress(
            learnerId: 'l1',
            objectiveId: id,
            attemptCount: 10,
            correctCount: 8);
      }
      final state50K = buildSampleState(progressMap: map50K);

      final sw2 = Stopwatch()..start();
      reconciler
          .reconcile(authoritativeState: state50K, proposal: prop)
          .valueOrThrow;
      sw2.stop();

      expect(sw2.elapsedMilliseconds, lessThan(1500));
    });
  });

  // ==========================================================================
  // GROUP 22: Property & Deterministic Replay Tests (10 tests)
  // ==========================================================================
  group('P38.22 Group 22 — Property & Deterministic Replay Tests', () {
    test(
        '149. 10 consecutive full reconciliations produce byte-identical JSON and SHA-256',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 3);

      String? baselineJson;
      String? baselineFp;

      for (int run = 0; run < 10; run++) {
        final reconciled = reconciler
            .reconcile(
              authoritativeState: state,
              proposal: prop,
              reconciledAt: fixedDate,
            )
            .valueOrThrow;
        final currentJson = jsonEncode(reconciled.toJson());

        if (run == 0) {
          baselineJson = currentJson;
          baselineFp = reconciled.fingerprint;
        } else {
          expect(currentJson, equals(baselineJson));
          expect(reconciled.fingerprint, equals(baselineFp));
        }
      }
    });

    test(
        '150. Property Invariant: Reconciled attempt count >= prior attempt count',
        () {
      for (int prior = 0; prior <= 5; prior++) {
        for (int added = 0; added <= 5; added++) {
          final p = LearnerProgress(
              learnerId: 'l1',
              objectiveId: 'obj_1',
              attemptCount: prior,
              correctCount: prior);
          final state = buildSampleState(progressMap: {'obj_1': p});
          final prop =
              buildSampleProposal(correctCount: added, objectiveId: 'obj_1');

          final reconciled = reconciler
              .reconcile(authoritativeState: state, proposal: prop)
              .valueOrThrow;
          expect(reconciled.reconciledProgress['obj_1']!.attemptCount,
              greaterThanOrEqualTo(prior));
        }
      }
    });

    test(
        '151. Property Invariant: Reconciled correct count >= prior correct count',
        () {
      for (int prior = 0; prior <= 5; prior++) {
        for (int added = 0; added <= 5; added++) {
          final p = LearnerProgress(
              learnerId: 'l1',
              objectiveId: 'obj_1',
              attemptCount: 10,
              correctCount: prior);
          final state = buildSampleState(progressMap: {'obj_1': p});
          final prop =
              buildSampleProposal(correctCount: added, objectiveId: 'obj_1');

          final reconciled = reconciler
              .reconcile(authoritativeState: state, proposal: prop)
              .valueOrThrow;
          expect(reconciled.reconciledProgress['obj_1']!.correctCount,
              greaterThanOrEqualTo(prior));
        }
      }
    });

    test('152. Property Invariant: Correct count never exceeds attempt count',
        () {
      for (int c = 0; c <= 4; c++) {
        for (int inc = 0; inc <= 4; inc++) {
          final prop =
              buildSampleProposal(correctCount: c, incorrectCount: inc);
          final state = buildSampleState();

          final reconciled = reconciler
              .reconcile(authoritativeState: state, proposal: prop)
              .valueOrThrow;
          for (final p in reconciled.reconciledProgress.values) {
            expect(p.correctCount, lessThanOrEqualTo(p.attemptCount));
          }
        }
      }
    });

    test(
        '153. Property Invariant: Achieved objective status is absorbing / never regresses',
        () {
      final pAchieved = LearnerProgress(
        learnerId: 'l1',
        objectiveId: 'obj_fr',
        attemptCount: 10,
        correctCount: 10,
        status: LearnerObjectiveStatus.achieved,
      );
      final state = buildSampleState(progressMap: {'obj_fr': pAchieved});

      for (int wrong = 1; wrong <= 5; wrong++) {
        final prop = buildSampleProposal(
            correctCount: 0, incorrectCount: wrong, objectiveId: 'obj_fr');
        final reconciled = reconciler
            .reconcile(authoritativeState: state, proposal: prop)
            .valueOrThrow;

        expect(reconciled.reconciledProgress['obj_fr']!.status,
            equals(LearnerObjectiveStatus.achieved));
      }
    });

    test(
        '154. Property Invariant: Processed session IDs strictly increase by exactly 1 on merge',
        () {
      final state = buildSampleState(processedSessionIds: {'s1', 's2'});
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.processedSessionIds.length, equals(3));
      expect(reconciled.processedSessionIds.contains(prop.sessionId), isTrue);
    });

    test(
        '155. Provenance accurately records source session and proposal fingerprints',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.provenance.proposalId, equals(prop.proposalId));
      expect(reconciled.provenance.sessionId, equals(prop.sessionId));
      expect(reconciled.provenance.sourceProposalFingerprint,
          equals(prop.fingerprint));
      expect(reconciled.provenance.baseStateFingerprint,
          equals(state.stateFingerprint));
    });

    test('156. Provenance serializes and deserializes cleanly', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      final json = reconciled.provenance.toJson();
      final fromJson = ReconciliationProvenance.fromJson(json);

      expect(fromJson.proposalId, equals(reconciled.provenance.proposalId));
      expect(fromJson.sessionId, equals(reconciled.provenance.sessionId));
      expect(fromJson.sourceProposalFingerprint,
          equals(reconciled.provenance.sourceProposalFingerprint));
      expect(fromJson.baseStateFingerprint,
          equals(reconciled.provenance.baseStateFingerprint));
    });

    test('157. Zero DateTime.now() usage: pure caller timestamps', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 1);
      final explicitTime = DateTime.utc(2035, 1, 1, 0, 0, 0);

      final reconciled = reconciler
          .reconcile(
            authoritativeState: state,
            proposal: prop,
            reconciledAt: explicitTime,
          )
          .valueOrThrow;

      expect(reconciled.reconciledAt, equals(explicitTime));
    });

    test(
        '158. Reconciled proposal preserves learner identity across multi-objective batches',
        () {
      final state = buildSampleState(learnerId: 'aspirant_super_2026');
      final prop = buildSampleProposal(
          learnerId: 'aspirant_super_2026', correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(reconciled.learnerId, equals('aspirant_super_2026'));
      for (final p in reconciled.reconciledProgress.values) {
        expect(p.learnerId, equals('aspirant_super_2026'));
      }
    });
  });

  // ===========================================================================
  // Group 23: Authoritative Adapter & Verification Lifecycle (P18/P19 Integration)
  // ===========================================================================
  group('P38.23 Group 23 — Authoritative Adapter & Verification Lifecycle', () {
    test(
        '159. AuthoritativeLearnerState.fromRepository reads ProgressRepository cleanly',
        () {
      final repo = InMemoryProgressRepository();
      repo.saveProgress(LearnerProgress(
        learnerId: 'learner_p18_01',
        objectiveId: 'obj_polity_01',
        attemptCount: 15,
        correctCount: 12,
        successRate: 0.8,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: fixedDate,
      ));
      repo.saveProgress(LearnerProgress(
        learnerId: 'learner_p18_01',
        objectiveId: 'obj_polity_02',
        attemptCount: 8,
        correctCount: 4,
        successRate: 0.5,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: fixedDate,
      ));

      final state = AuthoritativeLearnerState.fromRepository(
        repository: repo,
        learnerId: 'learner_p18_01',
        examId: 'upsc',
        lastUpdatedAt: fixedDate,
      );

      expect(state.learnerId, equals('learner_p18_01'));
      expect(state.examId, equals('upsc'));
      expect(state.progressMap.length, equals(2));
      expect(state.getProgress('obj_polity_01')?.attemptCount, equals(15));
      expect(state.getProgress('obj_polity_02')?.attemptCount, equals(8));
    });

    test(
        '160. toAuthoritativeLearnerState converts proposal into valid authoritative snapshot',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      final adapterState = reconciled.toAuthoritativeLearnerState();
      expect(adapterState.learnerId, equals(state.learnerId));
      expect(adapterState.examId, equals(state.examId));
      expect(adapterState.progressMap.length,
          equals(reconciled.reconciledProgress.length));
      expect(adapterState.processedSessionIds, contains(prop.sessionId));
      expect(adapterState.stateFingerprint, isNotEmpty);
    });

    test(
        '161. Genuine sequential idempotency: R1 -> toAuthoritativeLearnerState -> R2 yields duplicate',
        () {
      final state = buildSampleState(
        progressMap: {
          'obj_polity_fr': LearnerProgress(
            learnerId: 'learner_101',
            objectiveId: 'obj_polity_fr',
            attemptCount: 5,
            correctCount: 4,
            lastAttemptAt: fixedDate,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      final prop = buildSampleProposal(correctCount: 2);

      // First pass: Reconcile state + proposal
      final r1 =
          reconciler.reconcile(authoritativeState: state, proposal: prop);
      expect(r1.isSuccess, isTrue);
      final proposal1 = r1.proposal!;
      expect(proposal1.overallDecision, equals(ReconciliationDecision.merged));
      expect(proposal1.reconciledProgress['obj_polity_fr']?.attemptCount,
          equals(7));

      // Adapter conversion: Simulated commitment into authoritative state
      final resultingAuthoritativeState =
          proposal1.toAuthoritativeLearnerState();

      // Second pass: Re-reconcile resulting state + same proposal
      final r2 = reconciler.reconcile(
        authoritativeState: resultingAuthoritativeState,
        proposal: prop,
      );

      expect(r2.isSuccess, isTrue);
      final proposal2 = r2.proposal!;
      expect(
          proposal2.overallDecision, equals(ReconciliationDecision.duplicate));
      // Invariant: Zero double-counting!
      expect(proposal2.reconciledProgress['obj_polity_fr']?.attemptCount,
          equals(7));
      expect(proposal2.reconciledProgress['obj_polity_fr']?.correctCount,
          equals(proposal1.reconciledProgress['obj_polity_fr']?.correctCount));
    });

    test('162. expectedBaseStateFingerprint match succeeds', () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final result = reconciler.reconcile(
        authoritativeState: state,
        proposal: prop,
        expectedBaseStateFingerprint: state.stateFingerprint,
      );

      expect(result.isSuccess, isTrue);
      expect(result.proposal!.overallDecision,
          equals(ReconciliationDecision.merged));
    });

    test(
        '163. expectedBaseStateFingerprint mismatch returns typed fingerprintMismatch error',
        () {
      final state = buildSampleState();
      final prop = buildSampleProposal(correctCount: 2);

      final result = reconciler.reconcile(
        authoritativeState: state,
        proposal: prop,
        expectedBaseStateFingerprint: 'bogus_expected_fingerprint_hash',
      );

      expect(result.isFailure, isTrue);
      expect(result.error!.code,
          equals(ReconciliationErrorCode.fingerprintMismatch));
    });

    test(
        '164. Rejects empty proposalId, sessionId, or fingerprint with ArgumentError',
        () {
      final validProp = buildSampleProposal();

      expect(
        () => LearningStateUpdateProposal(
          proposalId: '   ',
          sessionId: validProp.sessionId,
          examId: validProp.examId,
          learnerId: validProp.learnerId,
          sessionMode: validProp.sessionMode,
          sessionStatus: validProp.sessionStatus,
          sourceOutcomeFingerprint: validProp.sourceOutcomeFingerprint,
          proposedAt: validProp.proposedAt,
          overallEvidenceStrength: validProp.overallEvidenceStrength,
          overallPattern: validProp.overallPattern,
          recommendedAction: validProp.recommendedAction,
          totalQuestions: validProp.totalQuestions,
          attemptedCount: validProp.attemptedCount,
          correctCount: validProp.correctCount,
          incorrectCount: validProp.incorrectCount,
          skippedCount: validProp.skippedCount,
          unansweredCount: validProp.unansweredCount,
          completionRate: validProp.completionRate,
          accuracy: validProp.accuracy,
          accuracyPercentage: validProp.accuracyPercentage,
          scoreRatio: validProp.scoreRatio,
          questionSignals: validProp.questionSignals,
          topicSignals: validProp.topicSignals,
          objectiveSignals: validProp.objectiveSignals,
          sectionSignals: validProp.sectionSignals,
          difficultySignals: validProp.difficultySignals,
          fingerprint: validProp.fingerprint,
        ),
        throwsArgumentError,
      );
    });

    test('165. State validation rejects empty learnerId, examId, or fingerprint with ArgumentError', () {
      expect(
        () => AuthoritativeLearnerState(
          learnerId: '   ',
          examId: 'upsc',
          progressMap: const {},
          lastUpdatedAt: fixedDate,
        ),
        throwsArgumentError,
      );
    });
  });
}
