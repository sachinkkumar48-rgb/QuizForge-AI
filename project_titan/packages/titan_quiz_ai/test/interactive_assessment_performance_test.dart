import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

void main() {
  group('Phase 8C: Interactive Assessment & Answer State Tests', () {
    late QuizQuestion sampleQ1;
    late QuizQuestion sampleQ2;
    late QuizQuestion sampleQ3;

    setUp(() {
      sampleQ1 = QuizQuestion(
        id: 'q_01',
        question:
            'Which Article of the Constitution establishes the Supreme Court?',
        options: const [
          QuizOption(id: '0', text: 'Article 124'),
          QuizOption(id: '1', text: 'Article 214'),
          QuizOption(id: '2', text: 'Article 324'),
          QuizOption(id: '3', text: 'Article 148'),
        ],
        correctAnswerIndex: 0,
        explanation:
            'Article 124 of the Constitution establishes the Supreme Court of India.',
        topic: 'Judiciary',
        marks: 2.0,
        negativeMarks: 0.66,
        pageReference: 12,
      );

      sampleQ2 = QuizQuestion(
        id: 'q_02',
        question: 'Is the Right to Property a Fundamental Right in India?',
        options: const [
          QuizOption(id: '0', text: 'True'),
          QuizOption(id: '1', text: 'False'),
        ],
        correctAnswerIndex: 1,
        explanation:
            'The 44th Constitutional Amendment made Right to Property a legal right under Article 300A.',
        topic: 'Fundamental Rights',
        marks: 2.0,
        negativeMarks: 0.66,
        pageReference: 8,
      );

      sampleQ3 = QuizQuestion(
        id: 'q_03',
        question:
            'Which of the following are Fundamental Duties under Article 51A?',
        options: const [
          QuizOption(
              id: '0',
              text: 'To abide by the Constitution and respect its ideals'),
          QuizOption(id: '1', text: 'To safeguard public property'),
          QuizOption(id: '2', text: 'To pay taxes regularly'),
          QuizOption(
              id: '3',
              text: 'To promote harmony and the spirit of common brotherhood'),
        ],
        correctAnswerIndex: 0,
        explanation: 'Payment of taxes is not listed under Article 51A.',
        topic: 'Fundamental Duties',
        marks: 3.0,
        negativeMarks: 1.0,
        pageReference: 15,
      );
    });

    test(
        '1. InteractiveQuestionState manages single selection and evaluation cleanly',
        () {
      var state = InteractiveQuestionState(
        question: sampleQ1,
        questionType: AssessmentQuestionType.mcq,
        sourceChunkId: 'chunk_judiciary_01',
        pageNumber: 12,
      );

      expect(state.status, AnswerStatus.unanswered);
      expect(state.isSelected, isFalse);
      expect(state.isSubmitted, isFalse);

      // Select Option A (index 0)
      state = state.selectSingleOption(0);
      expect(state.status, AnswerStatus.selected);
      expect(state.isSelected, isTrue);
      expect(state.primarySelectedOptionIndex, 0);

      // Submit and evaluate
      state = state.submitAndEvaluate();
      expect(state.status, AnswerStatus.correct);
      expect(state.isSubmitted, isTrue);
      expect(state.isCorrect, isTrue);
    });

    test('2. InteractiveQuestionState handles incorrect single selection', () {
      var state = InteractiveQuestionState(
        question: sampleQ1,
        questionType: AssessmentQuestionType.mcq,
      );

      // Select Option B (index 1, incorrect)
      state = state.selectSingleOption(1);
      state = state.submitAndEvaluate();

      expect(state.status, AnswerStatus.incorrect);
      expect(state.isSubmitted, isTrue);
      expect(state.isCorrect, isFalse);
    });

    test(
        '3. InteractiveQuestionState supports multi-select toggling and review marking',
        () {
      var state = InteractiveQuestionState(
        question: sampleQ3,
        questionType: AssessmentQuestionType.multipleSelect,
      );

      state = state.toggleMultipleOption(0);
      state = state.toggleMultipleOption(1);
      expect(state.selectedOptionIndices, {0, 1});

      // Toggle off index 1
      state = state.toggleMultipleOption(1);
      expect(state.selectedOptionIndices, {0});

      // Toggle review flag
      expect(state.isMarkedForReview, isFalse);
      state = state.toggleReviewFlag();
      expect(state.isMarkedForReview, isTrue);
      state = state.toggleReviewFlag();
      expect(state.isMarkedForReview, isFalse);
    });

    test(
        '4. AssessmentPerformanceAnalyzer computes deterministic scoring and topic metrics',
        () {
      const analyzer = AssessmentPerformanceAnalyzer(
        weakTopicThreshold: 0.60,
        strongTopicThreshold: 0.80,
      );

      final quiz = Quiz(
        id: 'quiz_polity',
        title: 'Indian Polity Assessment',
        sourceDocumentId: 'doc_polity_pdf',
        questions: [sampleQ1, sampleQ2, sampleQ3],
      );

      // Question 1: Correct (2.0 marks)
      final state1 = InteractiveQuestionState(
        question: sampleQ1,
        sourceChunkId: 'chk_1',
        pageNumber: 12,
      ).selectSingleOption(0).submitAndEvaluate();

      // Question 2: Incorrect (-0.66 marks)
      final state2 = InteractiveQuestionState(
        question: sampleQ2,
        sourceChunkId: 'chk_2',
        pageNumber: 8,
      ).selectSingleOption(0).submitAndEvaluate();

      // Question 3: Unanswered
      final state3 = InteractiveQuestionState(
        question: sampleQ3,
        sourceChunkId: 'chk_3',
        pageNumber: 15,
        isMarkedForReview: true,
      );

      final performance = analyzer.analyzePerformance(
        quiz: quiz,
        questionStates: {
          sampleQ1.id: state1,
          sampleQ2.id: state2,
          sampleQ3.id: state3,
        },
      );

      expect(performance.totalQuestions, 3);
      expect(performance.answeredQuestions, 2);
      expect(performance.correctAnswers, 1);
      expect(performance.incorrectAnswers, 1);
      expect(performance.unansweredQuestions, 1);
      expect(performance.maxScore, 7.0);
      expect(performance.score, closeTo(1.34, 0.01));
      expect(performance.percentage, closeTo((1.34 / 7.0) * 100, 0.1));

      expect(performance.reviewQuestionIds, [sampleQ3.id]);
      expect(performance.incorrectQuestionIds, [sampleQ2.id]);
      expect(performance.unansweredQuestionIds, [sampleQ3.id]);

      // Weak topics (< 60% accuracy): 'Fundamental Rights' (0%), 'Fundamental Duties' (0%)
      expect(performance.weakTopics,
          containsAll(['Fundamental Rights', 'Fundamental Duties']));
      // Strong topics (>= 80% accuracy): 'Judiciary' (100%)
      expect(performance.strongTopics, contains('Judiciary'));
    });

    test(
        '5. AssessmentPerformanceAnalyzer generates actionable remedial study recommendations with deep links',
        () {
      const analyzer = AssessmentPerformanceAnalyzer(
        weakTopicThreshold: 0.60,
      );

      final quiz = Quiz(
        id: 'quiz_polity',
        title: 'Indian Polity Assessment',
        sourceDocumentId: 'doc_polity_pdf',
        questions: [sampleQ1, sampleQ2, sampleQ3],
      );

      final state1 = InteractiveQuestionState(
        question: sampleQ1,
        sourceChunkId: 'chk_judiciary_01',
        pageNumber: 12,
      ).selectSingleOption(0).submitAndEvaluate();

      final state2 = InteractiveQuestionState(
        question: sampleQ2,
        sourceChunkId: 'chk_rights_01',
        pageNumber: 8,
      ).selectSingleOption(0).submitAndEvaluate();

      final state3 = InteractiveQuestionState(
        question: sampleQ3,
        sourceChunkId: 'chk_duties_01',
        pageNumber: 15,
      );

      final performance = analyzer.analyzePerformance(
        quiz: quiz,
        questionStates: {
          sampleQ1.id: state1,
          sampleQ2.id: state2,
          sampleQ3.id: state3,
        },
      );

      final recommendations = analyzer.generateRemedialRecommendations(
        quiz: quiz,
        performance: performance,
        questionStates: {
          sampleQ1.id: state1,
          sampleQ2.id: state2,
          sampleQ3.id: state3,
        },
      );

      expect(recommendations.length, 2);

      final rightsRec =
          recommendations.firstWhere((r) => r.topic == 'Fundamental Rights');
      expect(rightsRec.documentId, 'doc_polity_pdf');
      expect(rightsRec.primaryPageNumber, 8);
      expect(rightsRec.sourceChunkIds, contains('chk_rights_01'));
      expect(rightsRec.recommendedAction, RemedialActionType.reviewSource);
      expect(rightsRec.deepLinkRequest?.pageNumber, 8);
      expect(rightsRec.deepLinkRequest?.chunkId, 'chk_rights_01');
      expect(rightsRec.deepLinkRequest?.source, 'remedial_study_loop');
    });

    test('6. RetryMode provides clean strategy labels', () {
      expect(RetryMode.incorrect.label, 'Retry Incorrect');
      expect(RetryMode.unanswered.label, 'Retry Unanswered');
      expect(RetryMode.markedForReview.label, 'Retry Marked');
      expect(RetryMode.all.label, 'Restart Quiz');
    });
  });
}
