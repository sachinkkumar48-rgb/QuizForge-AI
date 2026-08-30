/// Product Loop Acceptance Test (TITAN Closed-Loop Product Integration).
///
/// Deterministic end-to-end integration test validating the complete closed loop:
/// 1. Learner
/// 2. Exam
/// 3. PYQ Question
/// 4. Objective Mapping
/// 5. Question Selection
/// 6. Answer Submission
/// 7. P18 Evidence
/// 8. P26 Diagnostic Result
/// 9. P23-Compatible Learning State (WeakSpotProfile)
/// 10. P24-Compatible Planning Input (StudyPlan)
/// 11. P25-Compatible Remedial Target (RemedialLesson & RemedialPracticeSessionConfig)
/// 12. Reassessment & Diagnostic Placement Advancement
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/models/answer_model.dart';
import 'package:garuda_pyq/models/option_model.dart';
import 'package:garuda_pyq/models/question_model.dart' as pyq;
import 'package:garuda_pyq/models/source_model.dart';

void main() {
  group('TITAN Product Loop Acceptance Test', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late ProgressTracker progressTracker;
    late AssessmentService assessmentService;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late DiagnosticAssessmentService diagnosticService;
    late DeterministicRemedialLessonService remedialService;
    late InMemoryRemedialLessonRepository remedialRepo;
    late LearningLoopOrchestrator loopOrchestrator;
    late PyqQuestionProvider pyqProvider;

    final fixedEvaluationTime = DateTime.utc(2026, 8, 29, 12, 0);

    setUp(() async {
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      learnerRepo = InMemoryLearnerRepository();
      attemptRepo = InMemoryAttemptRepository();
      progressRepo = InMemoryProgressRepository();
      progressTracker = ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
      );

      // 1. Learner
      learnerRepo.save(Learner(
        id: 'learner_titan_acceptance_01',
        name: 'TITAN Acceptance Learner',
        createdAt: DateTime.utc(2026, 8, 29),
      ));

      // 2 & 3. Exam & Canonical PYQ Questions
      final pyqQ1 = pyq.Question(
        id: 'PYQ_UPSC_2024_Q01',
        questionNumber: 1,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Basic Structure',
        questionType: pyq.QuestionType.mcq,
        originalQuestion:
            'Which landmark ruling established the Basic Structure Doctrine?',
        options: const [
          Option(
              key: 'A',
              text: 'Kesavananda Bharati v. State of Kerala',
              isCorrect: true),
          Option(
              key: 'B', text: 'Golaknath v. State of Punjab', isCorrect: false),
          Option(
              key: 'C',
              text: 'Minerva Mills v. Union of India',
              isCorrect: false),
          Option(
              key: 'D',
              text: 'Maneka Gandhi v. Union of India',
              isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC CSE Prelims 2024 Official Key',
        ),
        garudaExplanation:
            'Kesavananda Bharati (1973) 4 SCC 225 established the doctrine.',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'chk_pyq_2024_01',
          publisher: 'UPSC',
          retrievedDate: DateTime.utc(2024, 6, 1),
        ),
      );

      final pyqQ2 = pyq.Question(
        id: 'PYQ_UPSC_2024_Q02',
        questionNumber: 2,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Article 21',
        questionType: pyq.QuestionType.mcq,
        originalQuestion:
            'Procedure established by law in Article 21 was judicially interpreted as due process in:',
        options: const [
          Option(
              key: 'A',
              text: 'A.K. Gopalan v. State of Madras',
              isCorrect: false),
          Option(
              key: 'B',
              text: 'Maneka Gandhi v. Union of India',
              isCorrect: true),
          Option(
              key: 'C',
              text: 'Bachan Singh v. State of Punjab',
              isCorrect: false),
          Option(
              key: 'D',
              text: 'Sunil Batra v. Delhi Administration',
              isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['B'],
          officialAnswerSource: 'UPSC CSE Prelims 2024 Official Key',
        ),
        garudaExplanation:
            'Maneka Gandhi (1978) held that procedure must be just, fair and reasonable.',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'chk_pyq_2024_02',
          publisher: 'UPSC',
          retrievedDate: DateTime.utc(2024, 6, 1),
        ),
      );

      // 4. Objective Mapping
      pyqProvider = PyqQuestionProvider(
        questions: [pyqQ1, pyqQ2],
        topicOrTagToObjectiveIds: {
          'basic structure': ['lo_basic_structure_doctrine'],
          'article 21': ['lo_article_21_foundations'],
        },
      );

      // Assessment Service
      assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        questionProvider: pyqProvider,
        progressTracker: progressTracker,
      );

      // Diagnostic Placement Service
      diagnosticRepo = InMemoryDiagnosticPlacementRepository();
      diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: pyqProvider,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      // Remedial Service & Repository
      remedialRepo = InMemoryRemedialLessonRepository();
      await remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_acceptance',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21: Due Process & Liberty',
        summary:
            'Concise breakdown of procedure established by law vs substantive due process.',
        learningPoints: const [
          'A.K. Gopalan formalistic view',
          'Maneka Gandhi fair, just and reasonable doctrine',
        ],
        explanation:
            'Article 21 protection extends beyond arbitrary executive action to arbitrary legislation.',
        estimatedMinutes: 10,
        authoredAt: DateTime.utc(2026, 8, 29),
      ));
      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      // Unified Closed-Loop Orchestrator
      loopOrchestrator = LearningLoopOrchestrator(
        assessmentService: assessmentService,
        diagnosticService: diagnosticService,
        curriculumService: curriculumService,
        remedialService: remedialService,
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
      );
    });

    test(
        'Complete 12-Step Deterministic Product Loop: PYQ -> P18 -> P26 -> P23 -> P24 -> P25 -> Reassessment',
        () async {
      final learnerId = 'learner_titan_acceptance_01';

      // 5. Question Selection: Verify questions can be selected via provider
      final selectedQuestions = pyqProvider.getQuestionsForObjectives([
        'lo_basic_structure_doctrine',
        'lo_article_21_foundations',
      ]);
      expect(selectedQuestions.length, 2);
      expect(selectedQuestions.map((q) => q.id),
          containsAll(['PYQ_UPSC_2024_Q01', 'PYQ_UPSC_2024_Q02']));

      // 6. Answer Submission & 7. P18 Evidence Creation
      // Q1: Learner submits correct answer 'A'
      final result1 = loopOrchestrator.recordAssessmentAttempt(
        attemptId: 'att_loop_01',
        learnerId: learnerId,
        questionId: 'PYQ_UPSC_2024_Q01',
        objectiveId: 'lo_basic_structure_doctrine',
        submittedAnswer: 'A',
      );
      expect(result1.isCorrect, isTrue);
      expect(result1.score, 1.0);

      // Q2: Learner submits incorrect answer 'C' 3 times
      for (int i = 1; i <= 3; i++) {
        final res = loopOrchestrator.recordAssessmentAttempt(
          attemptId: 'att_loop_02_$i',
          learnerId: learnerId,
          questionId: 'PYQ_UPSC_2024_Q02',
          objectiveId: 'lo_article_21_foundations',
          submittedAnswer: 'C',
        );
        expect(res.isCorrect, isFalse);
        expect(res.score, 0.0);
      }

      // Verify P18 Evidence in Repository
      final learnerAttempts = attemptRepo.getAttemptsForLearner(learnerId);
      expect(learnerAttempts.length, 4);

      final progressObj1 =
          progressRepo.getProgress(learnerId, 'lo_basic_structure_doctrine');
      expect(progressObj1, isNotNull);
      expect(progressObj1!.attemptCount, 1);
      expect(progressObj1.correctCount, 1);

      final progressObj2 =
          progressRepo.getProgress(learnerId, 'lo_article_21_foundations');
      expect(progressObj2, isNotNull);
      expect(progressObj2!.attemptCount, 3);
      expect(progressObj2.correctCount, 0);

      // 8. P26 Diagnostic Placement Result
      final diagnosticResult = loopOrchestrator.runDiagnosticPlacement(
        learnerId: learnerId,
        targetObjectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations',
        ],
        evaluatedAt: fixedEvaluationTime,
      );

      expect(diagnosticResult.totalAssessedObjectives, 2);
      expect(diagnosticResult.totalAttemptsCount, 4);
      expect(diagnosticResult.totalCorrectCount, 1);
      expect(diagnosticResult.aggregateAccuracy, 0.25);

      // Diagnostic Placement statuses:
      // Objective 1 has 1 attempt (< 3 min) -> insufficientEvidence
      expect(
          diagnosticResult
              .objectiveResults['lo_basic_structure_doctrine']!.placementStatus,
          DiagnosticPlacementStatus.insufficientEvidence);
      // Objective 2 has 3 attempts, 0 correct -> developing & remediationTarget
      expect(
          diagnosticResult
              .objectiveResults['lo_article_21_foundations']!.placementStatus,
          DiagnosticPlacementStatus.developing);
      expect(diagnosticResult.frontier.remediationTargetObjectiveIds,
          contains('lo_article_21_foundations'));

      // 9. P23-Compatible Learning State (WeakSpotProfile)
      final weakSpots = loopOrchestrator.evaluateWeakSpots(
        learnerId: learnerId,
        objectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations',
        ],
        evaluatedAt: fixedEvaluationTime,
      );
      expect(weakSpots.weakObjectives.map((w) => w.objectiveId),
          contains('lo_article_21_foundations'));
      expect(weakSpots.weakObjectives.map((w) => w.objectiveId),
          isNot(contains('lo_basic_structure_doctrine')));

      // 10. P24-Compatible Planning Input (StudyPlan)
      final studyPlan = loopOrchestrator.generateFrontierStudyPlan(
        learnerId: learnerId,
        diagnosticResult: diagnosticResult,
        weakSpotProfile: weakSpots,
        planningStart: fixedEvaluationTime.add(const Duration(days: 1)),
        planningEnd: fixedEvaluationTime.add(const Duration(days: 2)),
      );
      expect(studyPlan.dailyAgendas, isNotEmpty);
      expect(
          studyPlan.dailyAgendas.first.items
              .any((item) => item.objectiveId == 'lo_basic_structure_doctrine'),
          isTrue);

      // 11. P25-Compatible Remedial Target (RemedialLesson & PracticeConfig)
      final remedialBindings = await loopOrchestrator.bindRemedialLessons(
        diagnosticResult: diagnosticResult,
      );
      expect(remedialBindings.containsKey('lo_article_21_foundations'), isTrue);
      final remedialLesson = remedialBindings['lo_article_21_foundations'];
      expect(remedialLesson, isNotNull);
      expect(remedialLesson!.lessonId, 'rem_art21_acceptance');

      // Create Remedial Reassessment Configuration
      final reassessmentConfig = loopOrchestrator.createReassessmentConfig(
        learnerId: learnerId,
        remedialLesson: remedialLesson,
        targetQuestionIds: ['PYQ_UPSC_2024_Q02'],
        createdAt: fixedEvaluationTime.add(const Duration(hours: 1)),
      );
      expect(reassessmentConfig.objectiveId, 'lo_article_21_foundations');
      expect(reassessmentConfig.hasTargetQuestions, isTrue);

      // 12. Reassessment & Placement Advancement
      // Learner studies the remedial lesson and performs 3 consecutive correct reassessment attempts
      for (int i = 1; i <= 3; i++) {
        final reassessRes = loopOrchestrator.submitReassessmentAttempt(
          attemptId: 'att_reassess_0$i',
          learnerId: learnerId,
          questionId: 'PYQ_UPSC_2024_Q02',
          objectiveId: 'lo_article_21_foundations',
          submittedAnswer: 'B', // Correct answer
        );
        expect(reassessRes.isCorrect, isTrue);
        expect(reassessRes.score, 1.0);
      }

      // Verify updated P18 progress after reassessment
      final updatedProgressObj2 =
          progressRepo.getProgress(learnerId, 'lo_article_21_foundations');
      expect(updatedProgressObj2!.attemptCount, 6); // 3 prior + 3 reassessment
      expect(
          updatedProgressObj2.correctCount, 3); // 3 correct now (50% accuracy)

      // Re-evaluate Diagnostic Placement after reassessment
      final postReassessmentDiagnostic = loopOrchestrator.reevaluatePlacement(
        learnerId: learnerId,
        targetObjectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations',
        ],
        evaluatedAt: fixedEvaluationTime.add(const Duration(hours: 2)),
      );

      // Objective 2 accuracy is now 3/6 = 0.50 (developing threshold met, no longer remediation target!)
      final updatedObj2Result = postReassessmentDiagnostic
          .objectiveResults['lo_article_21_foundations']!;
      expect(updatedObj2Result.observedAccuracy, 0.50);
      expect(postReassessmentDiagnostic.frontier.remediationTargetObjectiveIds,
          isEmpty);
    });
  });
}
