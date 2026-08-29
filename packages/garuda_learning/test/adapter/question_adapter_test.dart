/// Track 1 Generic Question Adapter & Provider Tests (TITAN-KO-026.0).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/models/answer_model.dart';
import 'package:garuda_pyq/models/option_model.dart';
import 'package:garuda_pyq/models/question_model.dart' as pyq;
import 'package:garuda_pyq/models/source_model.dart';

void main() {
  group('Track 1 Question Adapter Tests', () {
    test('LegalQuestionAdapter wraps LegalQuestion accurately', () {
      final legalQ = LegalQuestion(
        questionId: 'qa:case:TEST_CASE:issue:0',
        questionText: 'Whether Article 21 encompasses privacy rights?',
        questionType: LegalQuestionType.issue,
        sourceRefs: const ['case:TEST_CASE'],
        answer: StructuredAnswer(
          answerText: 'Yes, privacy is guaranteed under Article 21.',
          evidenceRefs: ['ev:001', 'case:TEST_CASE'],
          principles: ['privacy', 'dignity'],
          provenance: 'Judgment Holdings',
        ),
        provenance: 'Judgment Holdings',
        framing: 'Educational Analysis',
      );

      final adapter = LegalQuestionAdapter.fromLegalQuestion(
        legalQ,
        objectiveIds: ['lo_art21_privacy'],
        examMetadata: const QuestionExamMetadata(
          examId: 'upsc_cse',
          year: 2017,
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
        ),
      );

      // Verify IQuestionEntity contract
      expect(adapter.id, 'qa:case:TEST_CASE:issue:0');
      expect(adapter.prompt, 'Whether Article 21 encompasses privacy rights?');
      expect(adapter.expectedAnswer,
          'Yes, privacy is guaranteed under Article 21.');
      expect(adapter.explanation, contains('privacy'));
      expect(adapter.provenance, 'Judgment Holdings');
      expect(adapter.objectiveIds, ['lo_art21_privacy']);
      expect(adapter.examMetadata?.examId, 'upsc_cse');
      expect(adapter.examMetadata?.year, 2017);

      // Verify backward-compatibility: adapter IS LegalQuestion
      expect(adapter, isA<LegalQuestion>());
      expect(adapter.questionId, adapter.id);
      expect(adapter.questionText, adapter.prompt);
      expect(adapter.answer.answerText, adapter.expectedAnswer);
    });

    test(
        'PyqQuestionAdapter maps garuda_pyq.Question to IQuestionEntity & LegalQuestion',
        () {
      final pyqQ = pyq.Question(
        id: 'PYQ_UPSC_CSE_2024_GS1_Q014',
        questionNumber: 14,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS Paper I',
        subject: 'Indian Polity',
        topic: 'Constitutional Bodies',
        questionType: pyq.QuestionType.mcq,
        originalQuestion: 'Which of the following is a constitutional body?',
        options: const [
          Option(
              key: 'A', text: 'Election Commission of India', isCorrect: true),
          Option(key: 'B', text: 'NITI Aayog', isCorrect: false),
          Option(
              key: 'C',
              text: 'National Human Rights Commission',
              isCorrect: false),
          Option(
              key: 'D', text: 'Central Vigilance Commission', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC CSE 2024 Final Answer Key',
        ),
        garudaExplanation:
            'Article 324 provides for the Election Commission of India.',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in/prelims2024',
          checksum: 'abc123sha256',
          publisher: 'Union Public Service Commission',
          retrievedDate: DateTime.utc(2024, 6, 1),
        ),
        conceptsTested: const ['Article 324', 'Constitutional Bodies'],
      );

      final adapter = PyqQuestionAdapter.fromPyq(
        pyqQ,
        objectiveIds: ['lo_constitutional_bodies'],
      );

      // Verify IQuestionEntity properties
      expect(adapter.id, 'PYQ_UPSC_CSE_2024_GS1_Q014');
      expect(
          adapter.prompt, 'Which of the following is a constitutional body?');
      expect(adapter.options.length, 4);
      expect(adapter.options.first, 'A. Election Commission of India');
      expect(adapter.expectedAnswer, 'A');
      expect(adapter.explanation, contains('Article 324'));
      expect(adapter.provenance, contains('Union Public Service Commission'));
      expect(adapter.objectiveIds, ['lo_constitutional_bodies']);
      expect(adapter.examMetadata.examId, 'upsc_cse');
      expect(adapter.examMetadata.year, 2024);
      expect(adapter.examMetadata.paper, 'GS Paper I');

      // Verify backward-compatibility: adapter IS a LegalQuestion
      expect(adapter, isA<LegalQuestion>());
      expect(adapter.questionId, 'PYQ_UPSC_CSE_2024_GS1_Q014');
      expect(adapter.answer.answerText, 'A');
      expect(adapter.sourceRefs, isNotEmpty);
      expect(adapter.framing, contains('UPSC_CSE 2024'));

      // Verify scoring compatibility with MultipleChoiceEvaluator
      const evaluator = MultipleChoiceEvaluator();
      final attempt = QuestionAttempt(
        attemptId: 'att_001',
        learnerId: 'learner_101',
        questionId: adapter.id,
        objectiveId: 'lo_constitutional_bodies',
        submittedAnswer: 'A',
        attemptedAt: DateTime.utc(2026, 8, 29),
      );

      final result = evaluator.evaluate(attempt: attempt, question: adapter);
      expect(result.isCorrect, isTrue);
      expect(result.score, 1.0);

      // Verify incorrect attempt
      final incorrectAttempt = QuestionAttempt(
        attemptId: 'att_002',
        learnerId: 'learner_101',
        questionId: adapter.id,
        objectiveId: 'lo_constitutional_bodies',
        submittedAnswer: 'B',
        attemptedAt: DateTime.utc(2026, 8, 29),
      );
      final incorrectResult = evaluator.evaluate(
        attempt: incorrectAttempt,
        question: adapter,
      );
      expect(incorrectResult.isCorrect, isFalse);
      expect(incorrectResult.score, 0.0);
    });
  });

  group('Track 1 Question Provider Tests', () {
    test(
        'PyqQuestionProvider and CaseLawQuestionProvider coexist in CompositeQuestionProvider',
        () {
      final caseLawProduct = QuestionKnowledgeProduct(
        productId: 'qa:case:KESAVANANDA',
        sourceType: QuestionSourceType.caseLaw,
        sourceId: 'KESAVANANDA',
        sourceName: 'Kesavananda Bharati v. State of Kerala',
        questions: [
          LegalQuestion(
            questionId: 'qa:case:KESAVANANDA:issue:0',
            questionText: 'Can Parliament alter the basic structure?',
            questionType: LegalQuestionType.issue,
            sourceRefs: const ['case:KESAVANANDA'],
            answer: StructuredAnswer(
              answerText: 'No, basic structure cannot be altered.',
              evidenceRefs: ['case:KESAVANANDA'],
              principles: ['Basic Structure Doctrine'],
              provenance: 'Judgment Holdings',
            ),
            provenance: 'Judgment Holdings',
            framing: 'Constitutional Holdings',
          ),
        ],
      );

      final caseLawProvider = CaseLawQuestionProvider(
        prebuiltProducts: [caseLawProduct],
        productToObjectiveIds: {
          'qa:case:KESAVANANDA': ['lo_basic_structure'],
        },
      );

      final pyqQuestion = pyq.Question(
        id: 'PYQ_UPSC_CSE_2024_Q001',
        questionNumber: 1,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Parliament',
        questionType: pyq.QuestionType.mcq,
        originalQuestion: 'Consider statements regarding Money Bills...',
        options: const [
          Option(key: 'A', text: 'Statement 1 only', isCorrect: true),
          Option(key: 'B', text: 'Statement 2 only', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC',
        ),
        garudaExplanation: 'Article 110 defines Money Bill.',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'sha001',
          publisher: 'UPSC',
          retrievedDate: DateTime.utc(2024, 6, 1),
        ),
      );

      final pyqProvider = PyqQuestionProvider(
        questions: [pyqQuestion],
        topicOrTagToObjectiveIds: {
          'parliament': ['lo_parliament_money_bills'],
        },
      );

      final composite =
          CompositeQuestionProvider([caseLawProvider, pyqProvider]);

      // Resolve by objective
      final pyqResults =
          composite.getQuestionsForObjectives(['lo_parliament_money_bills']);
      expect(pyqResults.length, 1);
      expect(pyqResults.first.id, 'PYQ_UPSC_CSE_2024_Q001');

      final caseLawResults =
          composite.getQuestionsForObjectives(['lo_basic_structure']);
      expect(caseLawResults, isNotEmpty);

      // Resolve by unique ID
      final resolvedPyq = composite.getQuestionById('PYQ_UPSC_CSE_2024_Q001');
      expect(resolvedPyq, isNotNull);
      expect(resolvedPyq!.prompt, contains('Money Bills'));

      // Deterministic sorted output across calls
      final run1 = composite.getAllQuestions().map((q) => q.id).toList();
      final run2 = composite.getAllQuestions().map((q) => q.id).toList();
      expect(run1, run2);
    });

    test(
        'QuestionSelector selects from custom QuestionProvider deterministically',
        () {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);

      final inMemory = InMemoryQuestionProvider();
      final q1 = LegalQuestionAdapter(
        questionId: 'custom_q1',
        questionText: 'Custom Question 1',
        questionType: LegalQuestionType.topic,
        sourceRefs: const ['src:1'],
        answer: StructuredAnswer(
          answerText: 'Answer 1',
          evidenceRefs: ['ev:1'],
          principles: [],
          provenance: 'Test Suite',
        ),
        provenance: 'Test Suite',
        framing: 'Framing 1',
        objectiveIds: const ['lo_basic_structure_doctrine'],
      );
      final q2 = LegalQuestionAdapter(
        questionId: 'custom_q2',
        questionText: 'Custom Question 2',
        questionType: LegalQuestionType.topic,
        sourceRefs: const ['src:2'],
        answer: StructuredAnswer(
          answerText: 'Answer 2',
          evidenceRefs: ['ev:2'],
          principles: [],
          provenance: 'Test Suite',
        ),
        provenance: 'Test Suite',
        framing: 'Framing 2',
        objectiveIds: const ['lo_basic_structure_doctrine'],
      );

      inMemory.addQuestion(q1);
      inMemory.addQuestion(q2);

      final selector = QuestionSelector(
        questionProvider: inMemory,
        curriculumService: curriculumService,
      );

      final selected = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
      );

      expect(selected.length, 2);
      expect(selected[0].questionId, 'custom_q1');
      expect(selected[1].questionId, 'custom_q2');

      // Test limit parameter
      final limited = selector.selectQuestions(
        objectiveIds: ['lo_basic_structure_doctrine'],
        learnerId: 'learner_101',
        limit: 1,
      );
      expect(limited.length, 1);
      expect(limited.first.questionId, 'custom_q1');
    });
  });
}
