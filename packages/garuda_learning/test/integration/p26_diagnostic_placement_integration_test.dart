/// End-to-End Integration Pipeline Test (TITAN-KO-026.0 P26 & Track 1).
///
/// Proves the complete closed-loop architecture:
/// 1. PYQ Question (garuda_pyq)
/// 2. Question Provider & Adapter (Track 1)
/// 3. Assessment Evaluation & Progress Recording (P18)
/// 4. Diagnostic Assessment & Frontier Placement (P26)
/// 5. Dynamic Study Planning over Frontier (P24)
/// 6. Targeted Remedial Lesson Binding (P25)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/models/answer_model.dart';
import 'package:garuda_pyq/models/option_model.dart';
import 'package:garuda_pyq/models/question_model.dart' as pyq;
import 'package:garuda_pyq/models/source_model.dart';

void main() {
  group('P26 End-to-End Integration Pipeline Tests', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late ProgressTracker progressTracker;
    late AssessmentService assessmentService;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late DiagnosticAssessmentService diagnosticService;
    late DeterministicStudyPlannerService studyPlannerService;
    late DeterministicRemedialLessonService remedialService;
    late InMemoryRemedialLessonRepository remedialRepo;

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

      // Register test learner
      learnerRepo.save(Learner(
        id: 'learner_titan_01',
        name: 'TITAN Diagnostic Learner',
        createdAt: DateTime.utc(2026, 8, 29),
      ));

      // 1. Prepare Canonical PYQ Questions
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
            'Which case established the Basic Structure Doctrine?',
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
          officialAnswerSource: 'UPSC 2024',
        ),
        garudaExplanation:
            'Kesavananda Bharati (1973) established the Basic Structure Doctrine.',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'checksum001',
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
            'The procedure established by law in Article 21 was expanded in:',
        options: const [
          Option(key: 'A', text: 'A.K. Gopalan case', isCorrect: false),
          Option(key: 'B', text: 'Maneka Gandhi case', isCorrect: true),
          Option(key: 'C', text: 'Bachan Singh case', isCorrect: false),
          Option(key: 'D', text: 'Sunil Batra case', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['B'],
          officialAnswerSource: 'UPSC 2024',
        ),
        garudaExplanation:
            'Maneka Gandhi introduced the substantive due process requirement.',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'checksum002',
          publisher: 'UPSC',
          retrievedDate: DateTime.utc(2024, 6, 1),
        ),
      );

      // Track 1 Provider mapping
      final pyqProvider = PyqQuestionProvider(
        questions: [pyqQ1, pyqQ2],
        topicOrTagToObjectiveIds: {
          'basic structure': ['lo_basic_structure_doctrine'],
          'article 21': ['lo_article_21_foundations'],
        },
      );

      // 2. Initialize P18 Assessment Service with Question Provider
      assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        questionProvider: pyqProvider,
        progressTracker: progressTracker,
      );

      // 3. Initialize P26 Diagnostic Assessment Service
      diagnosticRepo = InMemoryDiagnosticPlacementRepository();
      diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: pyqProvider,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      // 4. Initialize P24 Planner Service
      studyPlannerService = const DeterministicStudyPlannerService();

      // 5. Initialize P25 Remedial Service
      remedialRepo = InMemoryRemedialLessonRepository();
      await remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_01',
        objectiveId: 'lo_article_21_foundations',
        title: 'Foundations of Article 21 & Due Process',
        summary:
            'Review of procedure established by law versus due process of law.',
        learningPoints: const [
          'Procedure established by law',
          'Substantive due process',
        ],
        explanation:
            'Article 21 guarantees right to life and personal liberty...',
        estimatedMinutes: 10,
        authoredAt: DateTime.utc(2026, 8, 29),
      ));

      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );
    });

    test(
        'Full lifecycle: PYQ -> Assessment -> Diagnostic -> Planner -> Remedial',
        () async {
      final now = DateTime.utc(2026, 8, 29, 10, 0);

      // Step A: Learner attempts PYQ question 1 (lo_basic_structure_doctrine) -> Correct
      final res1 = assessmentService.submitAttempt(
        attemptId: 'att_e2e_a1',
        learnerId: 'learner_titan_01',
        questionId: 'PYQ_UPSC_2024_Q01',
        objectiveId: 'lo_basic_structure_doctrine',
        submittedAnswer: 'A',
      );
      expect(res1.isCorrect, isTrue);
      expect(res1.score, 1.0);

      // Step B: Learner attempts PYQ question 2 (lo_article_21_foundations) 3 times -> All Incorrect
      for (int i = 1; i <= 3; i++) {
        final res = assessmentService.submitAttempt(
          attemptId: 'att_e2e_b$i',
          learnerId: 'learner_titan_01',
          questionId: 'PYQ_UPSC_2024_Q02',
          objectiveId: 'lo_article_21_foundations',
          submittedAnswer: 'C', // incorrect
        );
        expect(res.isCorrect, isFalse);
        expect(res.score, 0.0);
      }

      // Step C: Execute P26 Diagnostic Placement Evaluation
      final diagRequest = DiagnosticAssessmentRequest(
        requestId: 'req_full_pipeline',
        learnerId: 'learner_titan_01',
        targetObjectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations',
        ],
        requestedAt: now.add(const Duration(minutes: 30)),
      );

      final diagResult = diagnosticService.evaluatePlacement(diagRequest);

      // Verify P26 Diagnostic Output
      expect(diagResult.totalAssessedObjectives, 2);
      expect(diagResult.totalAttemptsCount, 4);
      expect(diagResult.totalCorrectCount, 1);
      expect(diagResult.aggregateAccuracy, 0.25);

      // Objective 1: 1 attempt -> Insufficient Evidence
      final obj1Result =
          diagResult.objectiveResults['lo_basic_structure_doctrine']!;
      expect(obj1Result.evidenceState,
          DiagnosticEvidenceState.insufficientEvidence);
      expect(obj1Result.placementStatus,
          DiagnosticPlacementStatus.insufficientEvidence);

      // Objective 2: 3 attempts, 0 correct -> Sufficient Evidence, Developing, Remediation Target
      final obj2Result =
          diagResult.objectiveResults['lo_article_21_foundations']!;
      expect(
          obj2Result.evidenceState, DiagnosticEvidenceState.sufficientEvidence);
      expect(obj2Result.placementStatus, DiagnosticPlacementStatus.developing);
      expect(obj2Result.observedAccuracy, 0.0);

      // Verify Placement Frontier:
      // lo_article_21_foundations is a remediation target (developing with low accuracy)
      expect(diagResult.frontier.remediationTargetObjectiveIds,
          contains('lo_article_21_foundations'));
      // lo_basic_structure_doctrine is on the active frontier because it is a prerequisite for Article 21
      expect(diagResult.frontier.activeFrontierObjectiveIds,
          contains('lo_basic_structure_doctrine'));

      // Step D: Feed P26 Frontier into P24 Dynamic Study Planner
      final availableFrontierObjectives = diagResult
          .frontier.activeFrontierObjectiveIds
          .map((id) => curriculumService.getObjectiveById(id))
          .whereType<LearningObjective>()
          .toList();

      final planRequest = StudyPlanRequest(
        learnerId: 'learner_titan_01',
        planningWindowStart: DateTime.utc(2026, 8, 30),
        planningWindowEnd: DateTime.utc(2026, 8, 31),
        scopedObjectiveIds: diagResult.frontier.activeFrontierObjectiveIds,
        requestedAt: now,
        timeBudget: StudyTimeBudget(
          learnerId: 'learner_titan_01',
          dailyAvailableMinutes: 60,
          preferredSessionDurationMinutes: 30,
          maxSessionsPerDay: 2,
          effectiveFrom: now,
        ),
      );

      final studyPlan = studyPlannerService.generatePlan(
        request: planRequest,
        availableObjectives: availableFrontierObjectives,
      );
      expect(studyPlan.dailyAgendas, isNotEmpty);
      final todayItems = studyPlan.dailyAgendas.first.items;
      expect(
          todayItems
              .any((item) => item.objectiveId == 'lo_basic_structure_doctrine'),
          isTrue);

      // Step E: Feed P26 Remediation Targets into P25 Remedial Framework
      for (final objId in diagResult.frontier.remediationTargetObjectiveIds) {
        final lesson = await remedialService.findBestLessonForObjective(
          objectiveId: objId,
        );
        expect(lesson, isNotNull);
        expect(lesson!.objectiveId, objId);
        expect(lesson.lessonId, 'rem_art21_01');
      }
    });
  });
}
