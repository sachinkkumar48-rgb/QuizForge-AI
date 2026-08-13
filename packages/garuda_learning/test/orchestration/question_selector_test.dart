import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:test/test.dart';

void main() {
  group('QuestionSelector Tests (TITAN-KO-019.0 P19)', () {
    late CurriculumService curriculumService;
    late QuestionKnowledgeProductService questionService;
    late InMemoryAttemptRepository attemptRepo;
    late QuestionSelector selector;

    setUp(() {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      questionService = QuestionKnowledgeProductService();
      attemptRepo = InMemoryAttemptRepository();
      selector = QuestionSelector(
        questionService: questionService,
        curriculumService: curriculumService,
        attemptRepository: attemptRepo,
      );
    });

    test('selectQuestions returns non-empty list for valid objectiveId', () {
      final questions = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
      );

      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(q.questionId, isNotEmpty);
        expect(q.answer.answerText, isNotEmpty);
      }
    });

    test('selectQuestions respects limit parameter', () {
      final questions = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
        limit: 2,
      );

      expect(questions.length, lessThanOrEqualTo(2));
    });

    test('selectQuestions unattemptedOnly filters attempted questions', () {
      final allQuestions = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
      );
      expect(allQuestions, isNotEmpty);

      // Record attempt for first question
      final attemptedQ = allQuestions.first;
      attemptRepo.saveAttempt(
        QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'learner_101',
          questionId: attemptedQ.questionId,
          objectiveId: 'lo_basic_structure_doctrine',
          submittedAnswer: 'test answer',
        ),
      );

      final unattempted = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
        policy: QuestionSelectionPolicy.unattemptedOnly,
      );

      expect(
        unattempted.any((q) => q.questionId == attemptedQ.questionId),
        false,
      );
    });

    test('selectQuestions returns empty list for empty objectiveIds', () {
      final questions = selector.selectQuestions(
        objectiveIds: [],
        learnerId: 'learner_101',
      );

      expect(questions, isEmpty);
    });

    test('selectQuestions output is strictly deterministic across calls', () {
      final run1 = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
      );

      final run2 = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
      );

      expect(
        run1.map((q) => q.questionId).toList(),
        equals(run2.map((q) => q.questionId).toList()),
      );
    });
  });
}
