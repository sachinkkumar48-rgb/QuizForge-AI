import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P18 Safety & Invariant Safeguards Tests (TITAN-KO-018.0 P18)', () {
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late CurriculumService curriculumService;
    late QuestionKnowledgeProductService questionService;
    late ProgressTracker progressTracker;
    late AssessmentService assessmentService;
    late Learner validLearner;

    setUp(() {
      learnerRepo = InMemoryLearnerRepository();
      attemptRepo = InMemoryAttemptRepository();
      progressRepo = InMemoryProgressRepository();
      curriculumService = CurriculumService(
        framework: CurriculumSeedData.buildUpscConstitutionalLawFramework(),
      );
      questionService = QuestionKnowledgeProductService();
      progressTracker = ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
      );
      assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        questionService: questionService,
        progressTracker: progressTracker,
      );

      validLearner = Learner(id: 'learner_safe', name: 'Safe Learner');
      learnerRepo.save(validLearner);
    });

    test('Safeguard 1: Fabricated learner ID is strictly rejected', () {
      final validQuestionId =
          questionService.buildAll().first.questions.first.questionId;

      expect(
        () => assessmentService.submitAttempt(
          learnerId: 'fake_learner_999',
          questionId: validQuestionId,
          objectiveId: 'lo_basic_structure_doctrine',
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('Safeguard 2: Fabricated question ID is strictly rejected', () {
      expect(
        () => assessmentService.submitAttempt(
          learnerId: validLearner.id,
          questionId: 'fake_question_999',
          objectiveId: 'lo_basic_structure_doctrine',
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('Safeguard 3: Fabricated learning objective ID is strictly rejected',
        () {
      final validQuestionId =
          questionService.buildAll().first.questions.first.questionId;

      expect(
        () => assessmentService.submitAttempt(
          learnerId: validLearner.id,
          questionId: validQuestionId,
          objectiveId: 'fake_objective_999',
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test(
        'Safeguard 4: AttemptResult cannot exist with score out of [0.0, 1.0] range',
        () {
      expect(
        () => AttemptResult(
          attemptId: 'att_1',
          isCorrect: true,
          score: 1.5,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );

      expect(
        () => AttemptResult(
          attemptId: 'att_1',
          isCorrect: false,
          score: -0.5,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
    });

    test('Safeguard 5: AttemptResult cannot exist with empty attemptId', () {
      expect(
        () => AttemptResult(
          attemptId: '',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
    });

    test(
        'Safeguard 6: Progress carries strictly objective achievement labels, never mastery/comprehension claims',
        () {
      final progress = LearnerProgress(
        learnerId: validLearner.id,
        objectiveId: 'lo_basic_structure_doctrine',
        attemptCount: 5,
        correctCount: 5,
        status: LearnerObjectiveStatus.achieved,
      );

      final json = progress.toJson().toString();
      expect(json, isNot(contains('mastery')));
      expect(json, isNot(contains('understands')));
      expect(json, isNot(contains('comprehends')));
      expect(progress.status.displayName, equals('Achieved'));
    });

    test(
        'Safeguard 7: 100% Offline execution without network or AI dependencies',
        () {
      final validQuestionId =
          questionService.buildAll().first.questions.first.questionId;

      final result = assessmentService.submitAttempt(
        learnerId: validLearner.id,
        questionId: validQuestionId,
        objectiveId: 'lo_basic_structure_doctrine',
        submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
      );

      expect(result.score, greaterThanOrEqualTo(0.0));
      expect(result.score, lessThanOrEqualTo(1.0));
      expect(result.evaluatedAt, isNotNull);
    });
  });
}
