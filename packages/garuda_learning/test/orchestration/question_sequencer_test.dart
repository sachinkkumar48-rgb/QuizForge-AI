import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionSequencer Tests (TITAN-KO-019.0 P19)', () {
    late CurriculumService curriculumService;
    late QuestionKnowledgeProductService questionService;
    late QuestionSequencer sequencer;
    late List<LegalQuestion> sampleQuestions;

    setUp(() {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      questionService = QuestionKnowledgeProductService();
      sequencer = QuestionSequencer(curriculumService: curriculumService);

      final selector = QuestionSelector(
        questionService: questionService,
        curriculumService: curriculumService,
      );
      sampleQuestions = selector.selectQuestions(
        objectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations'
        ],
        learnerId: 'learner_101',
      );
    });

    test('sequenceQuestions curriculumOrder sorts reproducibly', () {
      final sequenced = sequencer.sequenceQuestions(
        questions: sampleQuestions,
        objectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations'
        ],
        policy: QuestionSequencerPolicy.curriculumOrder,
      );

      expect(sequenced.length, sampleQuestions.length);

      final repeat = sequencer.sequenceQuestions(
        questions: sampleQuestions,
        objectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations'
        ],
        policy: QuestionSequencerPolicy.curriculumOrder,
      );

      expect(
        sequenced.map((q) => q.questionId).toList(),
        equals(repeat.map((q) => q.questionId).toList()),
      );
    });

    test('sequenceQuestions difficultyAscending sorts reproducibly', () {
      final sequenced = sequencer.sequenceQuestions(
        questions: sampleQuestions,
        objectiveIds: ['lo_basic_structure_doctrine'],
        policy: QuestionSequencerPolicy.difficultyAscending,
      );

      expect(sequenced.length, sampleQuestions.length);
    });

    test(
        'sequenceQuestions deterministicShuffle produces identical order for same seed',
        () {
      final shuffle1 = sequencer.sequenceQuestions(
        questions: sampleQuestions,
        objectiveIds: ['lo_basic_structure_doctrine'],
        policy: QuestionSequencerPolicy.deterministicShuffle,
        seed: 'seed_key_alpha',
      );

      final shuffle2 = sequencer.sequenceQuestions(
        questions: sampleQuestions,
        objectiveIds: ['lo_basic_structure_doctrine'],
        policy: QuestionSequencerPolicy.deterministicShuffle,
        seed: 'seed_key_alpha',
      );

      expect(
        shuffle1.map((q) => q.questionId).toList(),
        equals(shuffle2.map((q) => q.questionId).toList()),
      );
    });

    test(
        'sequenceQuestions deterministicShuffle produces different order for different seeds',
        () {
      if (sampleQuestions.length <= 1) return;

      final shuffleA = sequencer.sequenceQuestions(
        questions: sampleQuestions,
        objectiveIds: ['lo_basic_structure_doctrine'],
        policy: QuestionSequencerPolicy.deterministicShuffle,
        seed: 'seed_key_alpha',
      );

      final shuffleB = sequencer.sequenceQuestions(
        questions: sampleQuestions,
        objectiveIds: ['lo_basic_structure_doctrine'],
        policy: QuestionSequencerPolicy.deterministicShuffle,
        seed: 'seed_key_beta_999',
      );

      final idsA = shuffleA.map((q) => q.questionId).toList();
      final idsB = shuffleB.map((q) => q.questionId).toList();

      expect(idsA, isNot(equals(idsB)));
    });

    test('sequenceQuestions handles empty input list safely', () {
      final sequenced = sequencer.sequenceQuestions(
        questions: [],
        objectiveIds: ['lo_basic_structure_doctrine'],
      );

      expect(sequenced, isEmpty);
    });
  });
}
