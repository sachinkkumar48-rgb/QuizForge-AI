/// P39 Learner State Recovery End-to-End Integration Test.
///
/// Exercises the complete offline-first lifecycle:
/// Session 1: Cold start -> Practice -> Outcome Consolidation -> Reconciliation -> Persistence
/// Application Restart: Fresh service instance -> Load persisted state -> Validate/Recover
/// Session 2: Continued learning with recovered authoritative state -> Revision escalation -> Durability verification
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 15, 10, 0, 0);

  late InMemoryAuthoritativeLearningStateRepository repository;
  late AuthoritativeLearningStateRecoveryService recoveryService;
  late LearnerStatePersistenceService persistenceService;
  late AdaptivePracticeExecutionEngine engine;
  late AdaptivePracticeSessionOrchestrator orchestrator;
  late AdaptiveLearningStateReconciliationPipeline pipeline;

  setUp(() {
    repository = InMemoryAuthoritativeLearningStateRepository();
    recoveryService = AuthoritativeLearningStateRecoveryService(
      repository: repository,
    );
    persistenceService = LearnerStatePersistenceService(repository: repository);
    engine = const AdaptivePracticeExecutionEngine();
    orchestrator = const AdaptivePracticeSessionOrchestrator();
    pipeline = AdaptiveLearningStateReconciliationPipeline(
      repository: repository,
      recoveryService: recoveryService,
    );
  });

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
    String? learnerId = 'learner_e2e_42',
    required List<NormalizedQuestion> questions,
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
      sessionMode: PracticeSessionMode.standard,
      sectionSize: 5,
      estimatedSecondsPerQuestion: 60,
    );

    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: fixedDate,
    );
  }

  PracticeExecutionState buildExecution({
    required String examId,
    required String learnerId,
    required int correctCount,
    required int incorrectCount,
    required String questionPrefix,
    List<String>? objectiveIds,
  }) {
    final total = correctCount + incorrectCount;
    final questions = List.generate(
      total,
      (i) => buildQuestion(
        id: '${questionPrefix}_$i',
        examId: examId,
        objectiveIds: objectiveIds ?? ['obj_unit_${questionPrefix}_$i'],
      ),
    );
    final spec = buildSpec(
      examId: examId,
      learnerId: learnerId,
      questions: questions,
    );
    final initial = engine.initializeSession(spec: spec);
    var state =
        engine.startSession(state: initial, startedAt: fixedDate).valueOrThrow;

    int qIdx = 0;
    for (int i = 0; i < correctCount; i++, qIdx++) {
      state = engine
          .submitAnswer(
            state: state,
            questionId: '${questionPrefix}_$qIdx',
            answer: 'A',
            submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    for (int i = 0; i < incorrectCount; i++, qIdx++) {
      state = engine
          .submitAnswer(
            state: state,
            questionId: '${questionPrefix}_$qIdx',
            answer: 'B',
            submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    return state;
  }

  test(
    'Complete End-to-End Flow: Practice -> Outcome Consolidation -> Reconciliation -> Persistence -> Restart Recovery -> Continued Learning',
    () async {
      const learnerId = 'learner_e2e_42';
      const examId = 'upsc';

      // =======================================================================
      // STEP 1: First Session Cold Start
      // =======================================================================
      final coldState = await persistenceService.recoverOrCreate(
        learnerId: learnerId,
        examId: examId,
        timestamp: fixedDate,
      );

      expect(coldState.revision, equals(1));
      expect(coldState.progressMap, isEmpty);
      expect(coldState.processedSessionIds, isEmpty);

      // =======================================================================
      // STEP 2: Session 1 Practice Execution & Pipeline Reconciliation
      // =======================================================================
      final execution1 = buildExecution(
        examId: examId,
        learnerId: learnerId,
        questionPrefix: 's1',
        objectiveIds: const ['obj_polity_preamble'],
        correctCount: 3,
        incorrectCount: 1,
      );

      final pipelineResult1 = await pipeline.reconcileExecutionState(
        baseState: coldState,
        executionState: execution1,
        expectedRevision: 1,
        timestamp: fixedDate.add(const Duration(minutes: 10)),
      );

      expect(pipelineResult1.isSuccess, isTrue);
      expect(pipelineResult1.previousRevision, equals(1));
      expect(pipelineResult1.resultingRevision, equals(2));

      // =======================================================================
      // STEP 3: Application Restart (Cold Restart with Fresh Service Handle)
      // =======================================================================
      final restartService =
          LearnerStatePersistenceService(repository: repository);

      final recoveredState = await restartService.recoverOrCreate(
        learnerId: learnerId,
        examId: examId,
      );

      expect(recoveredState.revision, equals(2));
      expect(recoveredState.hasProcessedSession(execution1.sessionId), isTrue);
      expect(recoveredState.progressMap.containsKey('obj_polity_preamble'),
          isTrue);
      final preambleProgress =
          recoveredState.progressMap['obj_polity_preamble']!;
      expect(preambleProgress.attemptCount, equals(4));
      expect(preambleProgress.correctCount, equals(3));

      // =======================================================================
      // STEP 4: Idempotency Protection on Duplicate Session Replay
      // =======================================================================
      final duplicateReconciliation = await pipeline.reconcileExecutionState(
        baseState: recoveredState,
        executionState: execution1,
        expectedRevision: 2,
        timestamp: fixedDate.add(const Duration(minutes: 15)),
      );

      expect(duplicateReconciliation.isSuccess, isTrue);
      expect(duplicateReconciliation.isIdempotentReplay, isTrue);
      expect(duplicateReconciliation.resultingRevision, equals(2)); // Unchanged
      expect(
        duplicateReconciliation
            .resultingState!.progressMap['obj_polity_preamble']!.attemptCount,
        equals(4), // No double progress
      );

      // =======================================================================
      // STEP 5: Session 2 Continued Learning on New Objective
      // =======================================================================
      final execution2 = buildExecution(
        examId: examId,
        learnerId: learnerId,
        questionPrefix: 's2',
        objectiveIds: const ['obj_polity_fundamental_rights'],
        correctCount: 5,
        incorrectCount: 0,
      );

      final pipelineResult2 = await pipeline.reconcileExecutionState(
        baseState: recoveredState,
        executionState: execution2,
        expectedRevision: 2,
        timestamp: fixedDate.add(const Duration(hours: 1)),
      );

      expect(pipelineResult2.isSuccess, isTrue);
      expect(pipelineResult2.previousRevision, equals(2));
      expect(pipelineResult2.resultingRevision, equals(3));

      // =======================================================================
      // STEP 6: Second Restart & Final Durability Verification
      // =======================================================================
      final finalService =
          LearnerStatePersistenceService(repository: repository);
      final finalState = await finalService.load(
        learnerId: learnerId,
        examId: examId,
      );

      expect(finalState, isNotNull);
      expect(finalState!.revision, equals(3));
      expect(finalState.processedSessionIds,
          containsAll([execution1.sessionId, execution2.sessionId]));
      expect(finalState.progressMap.length, equals(2));
      expect(finalState.progressMap['obj_polity_preamble']!.attemptCount,
          equals(4));
      expect(
          finalState.progressMap['obj_polity_fundamental_rights']!.attemptCount,
          equals(5));
      expect(
          finalState.progressMap['obj_polity_fundamental_rights']!.correctCount,
          equals(5));
    },
  );
}
