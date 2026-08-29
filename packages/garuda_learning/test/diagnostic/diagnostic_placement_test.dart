/// P26 Diagnostic Assessment & Placement Engine Tests (TITAN-KO-026.0).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P26 Domain Entity Tests', () {
    test('DiagnosticEvidenceState enum properties and serialization', () {
      expect(DiagnosticEvidenceState.sufficientEvidence.hasSufficientEvidence,
          isTrue);
      expect(DiagnosticEvidenceState.insufficientEvidence.hasSufficientEvidence,
          isFalse);
      expect(
          DiagnosticEvidenceState.notAssessed.hasSufficientEvidence, isFalse);

      expect(DiagnosticEvidenceState.sufficientEvidence.displayName,
          'Sufficient Evidence');
      expect(DiagnosticEvidenceState.fromJson('sufficientEvidence'),
          DiagnosticEvidenceState.sufficientEvidence);
      expect(DiagnosticEvidenceState.fromJson('unknown_state'),
          DiagnosticEvidenceState.notAssessed);
    });

    test('DiagnosticPlacementStatus enum properties and serialization', () {
      expect(DiagnosticPlacementStatus.demonstrated.isDemonstrated, isTrue);
      expect(DiagnosticPlacementStatus.developing.isDeveloping, isTrue);
      expect(DiagnosticPlacementStatus.insufficientEvidence.isDemonstrated,
          isFalse);

      expect(
          DiagnosticPlacementStatus.demonstrated.displayName, 'Demonstrated');
      expect(DiagnosticPlacementStatus.fromJson('demonstrated'),
          DiagnosticPlacementStatus.demonstrated);
      expect(DiagnosticPlacementStatus.fromJson('unknown_status'),
          DiagnosticPlacementStatus.notAssessed);
    });

    test('DiagnosticThresholdConfig validation and defaults', () {
      const config = DiagnosticThresholdConfig();
      expect(config.minimumEvidenceThreshold, 3);
      expect(config.masteryThreshold, 0.70);
      expect(config.developingThreshold, 0.50);

      // JSON roundtrip
      final json = config.toJson();
      final roundtrip = DiagnosticThresholdConfig.fromJson(json);
      expect(roundtrip, config);

      // Assertions
      expect(() => DiagnosticThresholdConfig(minimumEvidenceThreshold: 0),
          throwsAssertionError);
      expect(() => DiagnosticThresholdConfig(masteryThreshold: 1.5),
          throwsAssertionError);
      expect(
          () => DiagnosticThresholdConfig(
              developingThreshold: 0.8, masteryThreshold: 0.7),
          throwsAssertionError);
    });

    test('DiagnosticObjectiveResult enforces educational safety invariants',
        () {
      final now = DateTime.utc(2026, 8, 29);

      // Zero attempts MUST have null accuracy
      final zeroResult = DiagnosticObjectiveResult(
        objectiveId: 'lo_basic_structure',
        evidenceState: DiagnosticEvidenceState.notAssessed,
        placementStatus: DiagnosticPlacementStatus.notAssessed,
        attemptsCount: 0,
        correctCount: 0,
        observedAccuracy: null,
        evaluatedAt: now,
        notes: 'No attempts.',
      );
      expect(zeroResult.observedAccuracy, isNull);

      // Invariant: Non-zero attempts cannot have null accuracy
      expect(
        () => DiagnosticObjectiveResult(
          objectiveId: 'lo_basic_structure',
          evidenceState: DiagnosticEvidenceState.insufficientEvidence,
          placementStatus: DiagnosticPlacementStatus.insufficientEvidence,
          attemptsCount: 2,
          correctCount: 1,
          observedAccuracy: null, // Illegal: must be non-null
          evaluatedAt: now,
          notes: 'Test',
        ),
        throwsAssertionError,
      );

      // Invariant: Accuracy bounds [0.0, 1.0]
      expect(
        () => DiagnosticObjectiveResult(
          objectiveId: 'lo_basic_structure',
          evidenceState: DiagnosticEvidenceState.sufficientEvidence,
          placementStatus: DiagnosticPlacementStatus.demonstrated,
          attemptsCount: 5,
          correctCount: 5,
          observedAccuracy: 1.2, // Out of bounds
          evaluatedAt: now,
          notes: 'Test',
        ),
        throwsAssertionError,
      );
    });
  });

  group('P26 Deterministic Diagnostic Evaluator Tests', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late DeterministicDiagnosticEvaluator evaluator;
    late InMemoryAttemptRepository attemptRepo;

    setUp(() {
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      evaluator = DeterministicDiagnosticEvaluator(
        curriculumService: curriculumService,
      );
      attemptRepo = InMemoryAttemptRepository();
    });

    test(
        'Zero attempts produces NOT_ASSESSED with null accuracy without failure penalty',
        () {
      final evaluatedAt = DateTime.utc(2026, 8, 29, 12, 0);
      final request = DiagnosticAssessmentRequest(
        requestId: 'req_001',
        learnerId: 'learner_101',
        targetObjectiveIds: ['lo_basic_structure_doctrine'],
        requestedAt: evaluatedAt,
      );

      final result = evaluator.evaluate(
        request: request,
        attemptRepository: attemptRepo,
      );

      expect(result.totalAttemptsCount, 0);
      expect(result.totalCorrectCount, 0);
      expect(result.aggregateAccuracy, isNull);
      expect(result.demonstratedObjectivesCount, 0);
      expect(result.totalAssessedObjectives, 0);

      final objResult = result.objectiveResults['lo_basic_structure_doctrine']!;
      expect(objResult.evidenceState, DiagnosticEvidenceState.notAssessed);
      expect(objResult.placementStatus, DiagnosticPlacementStatus.notAssessed);
      expect(objResult.observedAccuracy, isNull);
      expect(objResult.notes, contains('No assessment attempts'));

      expect(result.frontier.unassessedObjectiveIds,
          contains('lo_basic_structure_doctrine'));
      expect(result.frontier.activeFrontierObjectiveIds,
          contains('lo_basic_structure_doctrine'));
      expect(result.frontier.demonstratedObjectiveIds, isEmpty);
    });

    test('Sparse attempts below threshold produces INSUFFICIENT_EVIDENCE', () {
      final evaluatedAt = DateTime.utc(2026, 8, 29, 12, 0);

      // Record 2 attempts (threshold is 3)
      final att1 = QuestionAttempt(
        attemptId: 'att_1',
        learnerId: 'learner_101',
        questionId: 'q1',
        objectiveId: 'lo_basic_structure_doctrine',
        submittedAnswer: 'correct',
        attemptedAt: DateTime.utc(2026, 8, 28),
      );
      final att2 = QuestionAttempt(
        attemptId: 'att_2',
        learnerId: 'learner_101',
        questionId: 'q2',
        objectiveId: 'lo_basic_structure_doctrine',
        submittedAnswer: 'incorrect',
        attemptedAt: DateTime.utc(2026, 8, 28, 1),
      );
      attemptRepo.saveAttempt(att1);
      attemptRepo.saveResult(AttemptResult(
        attemptId: 'att_1',
        isCorrect: true,
        score: 1.0,
        feedback: 'Correct',
        evaluatedAt: DateTime.utc(2026, 8, 28),
        evaluationMethod: EvaluationMethod.multipleChoice,
      ));
      attemptRepo.saveAttempt(att2);
      attemptRepo.saveResult(AttemptResult(
        attemptId: 'att_2',
        isCorrect: false,
        score: 0.0,
        feedback: 'Incorrect',
        evaluatedAt: DateTime.utc(2026, 8, 28, 1),
        evaluationMethod: EvaluationMethod.multipleChoice,
      ));

      final request = DiagnosticAssessmentRequest(
        requestId: 'req_002',
        learnerId: 'learner_101',
        targetObjectiveIds: ['lo_basic_structure_doctrine'],
        requestedAt: evaluatedAt,
      );

      final result = evaluator.evaluate(
        request: request,
        attemptRepository: attemptRepo,
      );

      expect(result.totalAttemptsCount, 2);
      expect(result.totalCorrectCount, 1);
      expect(result.aggregateAccuracy, 0.50);
      expect(result.totalAssessedObjectives, 1);

      final objResult = result.objectiveResults['lo_basic_structure_doctrine']!;
      expect(objResult.evidenceState,
          DiagnosticEvidenceState.insufficientEvidence);
      expect(objResult.placementStatus,
          DiagnosticPlacementStatus.insufficientEvidence);
      expect(objResult.observedAccuracy, 0.50);
      expect(objResult.notes, contains('Sample insufficient'));

      expect(result.frontier.unassessedObjectiveIds,
          contains('lo_basic_structure_doctrine'));
    });

    test('Sufficient attempts with high accuracy yields DEMONSTRATED', () {
      final evaluatedAt = DateTime.utc(2026, 8, 29, 12, 0);

      // Record 4 attempts: 3 correct, 1 incorrect => 75% accuracy (>= 70% threshold)
      for (int i = 1; i <= 4; i++) {
        final att = QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: 'learner_101',
          questionId: 'q_$i',
          objectiveId: 'lo_basic_structure_doctrine',
          submittedAnswer: 'ans',
          attemptedAt: DateTime.utc(2026, 8, 28, i),
        );
        attemptRepo.saveAttempt(att);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_$i',
          isCorrect: i <= 3,
          score: i <= 3 ? 1.0 : 0.0,
          feedback: '',
          evaluatedAt: DateTime.utc(2026, 8, 28, i),
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      final request = DiagnosticAssessmentRequest(
        requestId: 'req_003',
        learnerId: 'learner_101',
        targetObjectiveIds: ['lo_basic_structure_doctrine'],
        requestedAt: evaluatedAt,
      );

      final result = evaluator.evaluate(
        request: request,
        attemptRepository: attemptRepo,
      );

      expect(result.totalAttemptsCount, 4);
      expect(result.totalCorrectCount, 3);
      expect(result.aggregateAccuracy, 0.75);
      expect(result.demonstratedObjectivesCount, 1);

      final objResult = result.objectiveResults['lo_basic_structure_doctrine']!;
      expect(
          objResult.evidenceState, DiagnosticEvidenceState.sufficientEvidence);
      expect(objResult.placementStatus, DiagnosticPlacementStatus.demonstrated);
      expect(objResult.observedAccuracy, 0.75);

      expect(result.frontier.demonstratedObjectiveIds,
          contains('lo_basic_structure_doctrine'));
      expect(result.frontier.activeFrontierObjectiveIds,
          isEmpty); // Already demonstrated
    });

    test(
        'Sufficient attempts with low accuracy yields DEVELOPING and marks remediation target',
        () {
      final evaluatedAt = DateTime.utc(2026, 8, 29, 12, 0);

      // Record 4 attempts: 1 correct, 3 incorrect => 25% accuracy (< 50% developingThreshold)
      for (int i = 1; i <= 4; i++) {
        final att = QuestionAttempt(
          attemptId: 'att_low_$i',
          learnerId: 'learner_101',
          questionId: 'q_low_$i',
          objectiveId: 'lo_article_21_foundations',
          submittedAnswer: 'ans',
          attemptedAt: DateTime.utc(2026, 8, 28, i),
        );
        attemptRepo.saveAttempt(att);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_low_$i',
          isCorrect: i == 1,
          score: i == 1 ? 1.0 : 0.0,
          feedback: '',
          evaluatedAt: DateTime.utc(2026, 8, 28, i),
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      final request = DiagnosticAssessmentRequest(
        requestId: 'req_004',
        learnerId: 'learner_101',
        targetObjectiveIds: ['lo_article_21_foundations'],
        requestedAt: evaluatedAt,
      );

      final result = evaluator.evaluate(
        request: request,
        attemptRepository: attemptRepo,
      );

      expect(result.totalAttemptsCount, 4);
      expect(result.totalCorrectCount, 1);
      expect(result.aggregateAccuracy, 0.25);

      final objResult = result.objectiveResults['lo_article_21_foundations']!;
      expect(
          objResult.evidenceState, DiagnosticEvidenceState.sufficientEvidence);
      expect(objResult.placementStatus, DiagnosticPlacementStatus.developing);
      expect(objResult.observedAccuracy, 0.25);

      expect(result.frontier.developingObjectiveIds,
          contains('lo_article_21_foundations'));
      // Since accuracy 25% < 50%, it is marked as a remediation target for P25
      expect(result.frontier.remediationTargetObjectiveIds,
          contains('lo_article_21_foundations'));
      expect(result.frontier.activeFrontierObjectiveIds,
          contains('lo_article_21_foundations'));
    });

    test(
        'DiagnosticAssessmentService coordinates question preparation, evaluation, and persistence',
        () {
      final inMemoryQuestions = InMemoryQuestionProvider();
      inMemoryQuestions.addQuestion(
        LegalQuestionAdapter(
          questionId: 'q_p26_1',
          questionText: 'Prompt 1',
          questionType: LegalQuestionType.topic,
          sourceRefs: const ['src:1'],
          answer: StructuredAnswer(
            answerText: 'Answer 1',
            evidenceRefs: ['src:1'],
            principles: [],
            provenance: 'P26 Test',
          ),
          provenance: 'P26 Test',
          framing: 'Framing 1',
          objectiveIds: const ['lo_basic_structure_doctrine'],
        ),
      );

      final learnerRepo = InMemoryLearnerRepository();
      learnerRepo.save(Learner(
        id: 'learner_p26',
        name: 'P26 Diagnostic Learner',
        createdAt: DateTime.utc(2026, 8, 29),
      ));

      final diagnosticRepo = InMemoryDiagnosticPlacementRepository();

      final service = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: inMemoryQuestions,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      // Question preparation
      final prepared = service.prepareDiagnosticQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionsPerObjective: 2,
      );
      expect(prepared.length, 1);
      expect(prepared.first.id, 'q_p26_1');

      // Evaluation
      final request = DiagnosticAssessmentRequest(
        requestId: 'req_service_01',
        learnerId: 'learner_p26',
        targetObjectiveIds: ['lo_basic_structure_doctrine'],
        requestedAt: DateTime.utc(2026, 8, 29, 15, 0),
      );

      final placement = service.evaluatePlacement(request);
      expect(placement.learnerId, 'learner_p26');
      expect(placement.assessmentId, 'diag_req_service_01');

      // Check persistence in repository
      final latest = service.getLatestPlacement('learner_p26');
      expect(latest, isNotNull);
      expect(latest!.assessmentId, 'diag_req_service_01');

      // Check error handling for unknown learner
      expect(
        () => service.evaluatePlacement(DiagnosticAssessmentRequest(
          requestId: 'req_fail',
          learnerId: 'unknown_learner',
          targetObjectiveIds: ['lo_basic_structure_doctrine'],
          requestedAt: DateTime.utc(2026, 8, 29),
        )),
        throwsArgumentError,
      );

      // Check error handling for unknown objective
      expect(
        () => service.evaluatePlacement(DiagnosticAssessmentRequest(
          requestId: 'req_fail',
          learnerId: 'learner_p26',
          targetObjectiveIds: ['non_existent_objective'],
          requestedAt: DateTime.utc(2026, 8, 29),
        )),
        throwsArgumentError,
      );
    });
  });
}
