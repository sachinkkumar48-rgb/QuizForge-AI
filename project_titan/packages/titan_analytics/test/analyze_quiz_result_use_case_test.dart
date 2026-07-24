import 'package:test/test.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_quiz/titan_quiz.dart';

void main() {
  group('AnalyzeQuizResultUseCase & ResultAnalyticsRepositoryImpl', () {
    late ResultAnalyticsRepository repository;
    late AnalyzeQuizResultUseCase useCase;

    setUp(() {
      repository = ResultAnalyticsRepositoryImpl();
      useCase = AnalyzeQuizResultUseCase(repository);
    });

    test('should analyze QuizResult and return comprehensive ResultAnalytics',
        () async {
      final quizResult = QuizResult(
        quizId: 'quiz_123',
        attempted: 10,
        correct: 8,
        wrong: 2,
        unanswered: 0,
        score: 15.34,
        maxScore: 20.0,
        percentage: 76.7,
        answers: const [
          UserAnswer(questionId: 'q1', selectedOptionIndex: 0),
          UserAnswer(questionId: 'q2', selectedOptionIndex: 1),
        ],
      );

      final analytics = await useCase.execute(quizResult);

      expect(analytics.quizResult, equals(quizResult));
      expect(analytics.scoreMetrics.scoreObtained, equals(15.34));
      expect(analytics.scoreMetrics.percentage, equals(76.7));
      expect(analytics.scoreMetrics.accuracy, equals(80.0));
      expect(analytics.scoreMetrics.status, equals('Excellent'));

      expect(analytics.topicPerformances, isNotEmpty);
      expect(analytics.mistakeAnalysis.keyMistakeInsights, isNotEmpty);
      expect(analytics.mentorFeedback.strengths, isNotEmpty);
      expect(analytics.revisionRecommendation.recommendedTopics, isNotEmpty);
      expect(analytics.pyqCorrelation.relevanceScore, greaterThan(0));
    });

    test('should extract topic performance when Quiz object is provided',
        () async {
      final quizResult = QuizResult(
        quizId: 'quiz_123',
        attempted: 2,
        correct: 1,
        wrong: 1,
        unanswered: 0,
        score: 1.67,
        maxScore: 4.0,
        percentage: 41.75,
        answers: const [
          UserAnswer(questionId: 'q1', selectedOptionIndex: 0),
          UserAnswer(questionId: 'q2', selectedOptionIndex: 2),
        ],
      );

      final quiz = Quiz(
        id: 'quiz_123',
        title: 'Polity & History Test',
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'Question 1',
            options: const [QuizOption(id: 'o1', text: 'Opt 1')],
            correctAnswerIndex: 0,
            topic: 'Polity',
          ),
          QuizQuestion(
            id: 'q2',
            question: 'Question 2',
            options: const [QuizOption(id: 'o2', text: 'Opt 2')],
            correctAnswerIndex: 0,
            topic: 'History',
          ),
        ],
      );

      final analytics = await useCase.execute(quizResult, quiz: quiz);

      expect(analytics.topicPerformances.length, equals(2));
      final polity =
          analytics.topicPerformances.firstWhere((t) => t.topic == 'Polity');
      expect(polity.accuracy, equals(100.0));
      expect(polity.masteryLevel, equals('Master'));

      final history =
          analytics.topicPerformances.firstWhere((t) => t.topic == 'History');
      expect(history.accuracy, equals(0.0));
      expect(history.masteryLevel, equals('Needs Focus'));
    });
  });
}
