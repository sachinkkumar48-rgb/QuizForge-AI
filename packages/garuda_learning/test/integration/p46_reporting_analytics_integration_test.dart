/// P46 Learner Reporting & Analytics Closed-Loop Integration Test (TITAN-KO-046.0 P46).
///
/// Implements and verifies the Section 11 authoritative scenario:
///
/// NEW LEARNER (Cold Start)
///  ↓
/// OPEN ANALYTICS
///  ↓
/// EMPTY / LOW-DATA STATE
///  ↓
/// OPEN LEARNING PATH
///  ↓
/// COMPLETE REAL PRACTICE
///  ↓
/// OUTCOME CONSOLIDATION
///  ↓
/// AUTHORITATIVE STATE RECONCILIATION
///  ↓
/// ANALYTICS REFRESH
///  ↓
/// ATTEMPTS INCREASE
///  ↓
/// ACCURACY UPDATED
///  ↓
/// OBJECTIVE STATUS UPDATED
///  ↓
/// WEAK AREA / MASTERY DISTRIBUTION UPDATED
///  ↓
/// NEXT-BEST ACTION REFLECTS CURRENT STATE
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P46 Reporting & Analytics Closed-Loop Product Acceptance Test', () {
    const String testLearner = 'learner_p46_closed_loop';
    const String testExam = 'upsc_prelims_gs1';
    final DateTime initialDate = DateTime.utc(2026, 9, 8, 9, 0, 0);

    const proposer = LearningStateUpdateProposer();
    const consolidator = PracticeOutcomeConsolidator();
    const engine = AdaptivePracticeExecutionEngine();

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late InMemoryLearningActivityCompletionRepository completionRepo;
    late InMemoryFacultyContentRepository facultyRepo;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late MasteryProgressionService masteryService;
    late AdaptiveLearningStateReconciler reconciler;
    late AdaptiveLearningStateReconciliationPipeline pipeline;
    late LearnerAnalyticsService analyticsService;

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      checkpointRepo = InMemorySessionCheckpointRepository();
      completionRepo = InMemoryLearningActivityCompletionRepository();
      facultyRepo = InMemoryFacultyContentRepository();

      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      masteryService = MasteryProgressionService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
      );

      reconciler = const AdaptiveLearningStateReconciler();
      pipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        reconciler: reconciler,
        proposer: proposer,
        consolidator: consolidator,
      );

      analyticsService = LearnerAnalyticsService(
        curriculumService: curriculumService,
        masteryService: masteryService,
        authRecoveryService: authRecoveryService,
        completionRepository: completionRepo,
        checkpointRepository: checkpointRepo,
        facultyRepository: facultyRepo,
      );
    });

    NormalizedQuestion buildQuestion({
      required String id,
      required String objectiveId,
    }) {
      return NormalizedQuestion(
        id: id,
        examId: testExam,
        year: 2024,
        paper: 'GS1',
        subject: 'Indian Polity & Governance',
        topic: 'Constitutional Framework',
        normalizedText: 'Question stem for $id',
        originalText: 'Question stem for $id',
        options: const [
          Option(key: 'A', text: 'Option A (Correct)', isCorrect: true),
          Option(key: 'B', text: 'Option B', isCorrect: false),
          Option(key: 'C', text: 'Option C', isCorrect: false),
          Option(key: 'D', text: 'Option D', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC Key 2024',
        ),
        explanation: 'Official explanation for $id',
        difficulty: 'Medium',
        source: PyqSourceReference.official(
          examId: testExam,
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

    const orchestrator = AdaptivePracticeSessionOrchestrator();

    AdaptivePracticeSessionSpec buildSpec({
      required List<NormalizedQuestion> questions,
    }) {
      final candidates = questions
          .map((q) => AdaptiveQuestionCandidate(
                question: q,
                historicalPriority: 0.5,
                learnerWeakness: 0.5,
                exposureCount: 0,
                recencyScore: 1.0,
                difficultyFit: 0.8,
                sourceQualityScore: 1.0,
                selectionScore: 0.75,
                isEligible: true,
                scoreBreakdown: const {},
              ))
          .toList();

      final selectionResult = AdaptiveQuestionSelectionResult(
        examId: testExam,
        selectedQuestions: questions,
        selectedCandidates: candidates,
        allCandidates: candidates,
        requestedCount: questions.length,
        eligibleCount: questions.length,
        config: AdaptiveQuestionSelectionConfig(
          examId: testExam,
          targetQuestionCount: questions.length,
        ),
        selectedAt: initialDate,
      );

      final config = AdaptivePracticeSessionConfig(
        examId: testExam,
        learnerId: testLearner,
        sessionMode: PracticeSessionMode.standard,
        sectionSize: 5,
        estimatedSecondsPerQuestion: 60,
      );

      return orchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: config,
        orchestratedAt: initialDate,
      );
    }

    test(
        'Section 11 Closed-Loop Acceptance Test: New Learner to Practice, Reconcile, and Analytics Refresh',
        () async {
      // -----------------------------------------------------------------------
      // Step 1: NEW LEARNER (Cold Start Recovery)
      // -----------------------------------------------------------------------
      final coldStartRecovery = await authRecoveryService.recover(
        learnerId: testLearner,
        examId: testExam,
        requestedAt: initialDate,
        persistInitialIfAbsent: true,
      );
      expect(coldStartRecovery.isSuccess, isTrue);
      final initialState = coldStartRecovery.state!;
      expect(initialState.progressMap, isEmpty);

      // -----------------------------------------------------------------------
      // Step 2: OPEN ANALYTICS (Initial Empty State)
      // -----------------------------------------------------------------------
      final initialReport = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: initialState,
        asOfDate: initialDate,
      );

      expect(initialReport.isEmpty, isTrue);
      expect(initialReport.hasData, isFalse);
      expect(initialReport.summary.totalAttempts, equals(0));
      expect(initialReport.summary.correctCount, equals(0));
      expect(initialReport.summary.accuracy, equals(0.0));
      expect(initialReport.summary.objectivesAttempted, equals(0));
      expect(initialReport.summary.objectivesMastered, equals(0));
      expect(initialReport.weakAreas, isEmpty);
      expect(initialReport.performanceTrends, isEmpty);
      expect(initialReport.masteryDistribution[ProgressionStage.notStarted],
          equals(framework.allObjectives.length));

      // -----------------------------------------------------------------------
      // Step 3: OPEN LEARNING PATH & COMPLETE REAL PRACTICE
      // -----------------------------------------------------------------------
      final questions = [
        buildQuestion(id: 'q_preamble_1', objectiveId: 'lo_preamble_identity'),
        buildQuestion(id: 'q_preamble_2', objectiveId: 'lo_preamble_identity'),
        buildQuestion(id: 'q_preamble_3', objectiveId: 'lo_preamble_identity'),
        buildQuestion(id: 'q_preamble_4', objectiveId: 'lo_preamble_identity'),
      ];

      final spec = buildSpec(questions: questions);

      final initialExecution = engine.initializeSession(spec: spec);
      var executionState = engine
          .startSession(state: initialExecution, startedAt: initialDate)
          .valueOrThrow;

      // Submit 1 correct, 3 incorrect answers -> 25% accuracy (remediation needed)
      executionState = engine
          .submitAnswer(
            state: executionState,
            questionId: 'q_preamble_1',
            answer: 'A', // Correct
            submittedAt: initialDate.add(const Duration(minutes: 2)),
          )
          .valueOrThrow;

      executionState = engine
          .submitAnswer(
            state: executionState,
            questionId: 'q_preamble_2',
            answer: 'B', // Incorrect
            submittedAt: initialDate.add(const Duration(minutes: 4)),
          )
          .valueOrThrow;

      executionState = engine
          .submitAnswer(
            state: executionState,
            questionId: 'q_preamble_3',
            answer: 'C', // Incorrect
            submittedAt: initialDate.add(const Duration(minutes: 6)),
          )
          .valueOrThrow;

      executionState = engine
          .submitAnswer(
            state: executionState,
            questionId: 'q_preamble_4',
            answer: 'D', // Incorrect
            submittedAt: initialDate.add(const Duration(minutes: 8)),
          )
          .valueOrThrow;

      // -----------------------------------------------------------------------
      // Step 4 & 5: OUTCOME CONSOLIDATION & AUTHORITATIVE STATE RECONCILIATION
      // -----------------------------------------------------------------------
      final pipelineResult = await pipeline.reconcileExecutionState(
        baseState: initialState,
        executionState: executionState,
        expectedRevision: initialState.revision,
      );

      expect(pipelineResult.isSuccess, isTrue);
      expect(pipelineResult.resultingState, isNotNull);
      final updatedState = pipelineResult.resultingState!;

      // Verify authoritative state reconciled the attempts
      expect(
          updatedState.progressMap.containsKey('lo_preamble_identity'), isTrue);
      final progress = updatedState.progressMap['lo_preamble_identity']!;
      expect(progress.attemptCount, equals(4));
      expect(progress.correctCount, equals(1));
      expect(progress.successRate, closeTo(0.25, 0.001));

      // -----------------------------------------------------------------------
      // Step 6: ANALYTICS REFRESH
      // -----------------------------------------------------------------------
      final refreshDate = initialDate.add(const Duration(minutes: 10));
      final refreshedReport = await analyticsService.computeLearnerReport(
        learnerId: testLearner,
        examId: testExam,
        authState: updatedState,
        asOfDate: refreshDate,
      );

      // -----------------------------------------------------------------------
      // Step 7: VERIFY ATTEMPTS INCREASE
      // -----------------------------------------------------------------------
      expect(refreshedReport.hasData, isTrue);
      expect(refreshedReport.isEmpty, isFalse);
      expect(refreshedReport.summary.totalAttempts, equals(4));
      expect(refreshedReport.summary.totalAttempts,
          greaterThan(initialReport.summary.totalAttempts));

      // -----------------------------------------------------------------------
      // Step 8: VERIFY ACCURACY UPDATED
      // -----------------------------------------------------------------------
      expect(refreshedReport.summary.correctCount, equals(1));
      expect(refreshedReport.summary.incorrectCount, equals(3));
      expect(refreshedReport.summary.accuracy, closeTo(0.25, 0.001));
      expect(refreshedReport.summary.accuracyPercentage, closeTo(25.0, 0.001));

      // -----------------------------------------------------------------------
      // Step 9: VERIFY OBJECTIVE STATUS UPDATED
      // -----------------------------------------------------------------------
      expect(refreshedReport.summary.objectivesAttempted, equals(1));
      expect(refreshedReport.summary.objectivesNeedingRemediation, equals(1));

      // -----------------------------------------------------------------------
      // Step 10: VERIFY WEAK AREA / MASTERY DISTRIBUTION UPDATED
      // -----------------------------------------------------------------------
      expect(
          refreshedReport
              .masteryDistribution[ProgressionStage.remediationRequired],
          equals(1));
      expect(refreshedReport.masteryDistribution[ProgressionStage.notStarted],
          equals(framework.allObjectives.length - 1));

      expect(refreshedReport.weakAreas, isNotEmpty);
      final weakObjective = refreshedReport.weakAreas.first;
      expect(weakObjective.id, equals('lo_preamble_identity'));
      expect(weakObjective.accuracy, closeTo(0.25, 0.001));
      expect(weakObjective.isRemediationRequired, isTrue);

      // -----------------------------------------------------------------------
      // Step 11: NEXT-BEST ACTION REFLECTS CURRENT STATE
      // -----------------------------------------------------------------------
      expect(weakObjective.recommendedAction, isNotEmpty);
      expect(weakObjective.stage, equals(ProgressionStage.remediationRequired));

      // Verify curriculum drilldown contains updated data
      final politySubject = refreshedReport.subjects.first;
      expect(politySubject.questionsAttempted, equals(4));
      expect(politySubject.correctCount, equals(1));
      expect(politySubject.accuracy, closeTo(0.25, 0.001));

      // Verify trend point captured
      expect(refreshedReport.performanceTrends, isNotEmpty);
      expect(refreshedReport.performanceTrends.first.attempts, equals(4));
      expect(refreshedReport.performanceTrends.first.correctCount, equals(1));
    });
  });
}
