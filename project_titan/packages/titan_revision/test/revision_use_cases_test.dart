import 'package:test/test.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('GenerateRevisionQueueUseCase & RevisionRepositoryImpl', () {
    late RevisionRepositoryImpl repository;
    late GenerateRevisionQueueUseCase generateUseCase;
    late ProcessRevisionAttemptUseCase processUseCase;

    setUp(() {
      repository = RevisionRepositoryImpl();
      generateUseCase = GenerateRevisionQueueUseCase(repository);
      processUseCase = ProcessRevisionAttemptUseCase(repository);
    });

    test('should fetch initial seeded revision queue with counts and summary',
        () async {
      final queue = await generateUseCase.execute();

      expect(queue.items, isNotEmpty);
      expect(queue.userId, equals('user_titan'));
      expect(queue.overdueCount, greaterThanOrEqualTo(0));
      expect(queue.dueTodayCount, greaterThanOrEqualTo(0));
    });

    test('should filter revision queue by category', () async {
      final queue = await generateUseCase.execute(category: 'Indian Polity');

      expect(queue.items, isNotEmpty);
      expect(queue.items.every((i) => i.topic == 'Indian Polity'), isTrue);
    });

    test('should ingest weak topics from ResultAnalytics into revision queue',
        () async {
      final now = DateTime.now();

      final analytics = ResultAnalytics(
        quizResult: QuizResult(
          quizId: 'quiz_01',
          attempted: 10,
          correct: 5,
          wrong: 5,
          unanswered: 0,
          score: 10.0,
          maxScore: 20.0,
          percentage: 50.0,
        ),
        scoreMetrics: const ScoreMetrics(
          scoreObtained: 10.0,
          maxScore: 20.0,
          percentage: 50.0,
          totalQuestions: 10,
          correctCount: 5,
          wrongCount: 5,
          unansweredCount: 0,
          timeTaken: Duration(minutes: 10),
          accuracy: 50.0,
          percentileRank: 50.0,
          status: 'Needs Practice',
        ),
        topicPerformances: const [
          TopicPerformance(
            topic: 'Environment',
            totalQuestions: 4,
            correctCount: 1,
            wrongCount: 3,
            accuracy: 25.0,
            masteryLevel: 'Novice',
          ),
        ],
        mistakeAnalysis: const MistakeAnalysis.constAnalysis(
          conceptualErrors: 3,
          sillyErrors: 1,
          timePressureErrors: 1,
          skippedCount: 0,
          keyMistakeInsights: ['Review Ramsar sites'],
        ),
        mentorFeedback: const MentorFeedback.constFeedback(
          summary: 'Focus on Environment',
          strengths: ['History'],
          weakAreas: ['Environment'],
          recommendation: 'Revise Ramsar sites',
          actionPlan: ['Daily active recall'],
        ),
        revisionRecommendation: RevisionRecommendation.constRecommendation(
          recommendedTopics: ['Environment'],
          priorityLevel: 'Urgent',
          scheduledDate: now,
          suggestedResources: ['https://example.com/ramsar'],
        ),
        pyqCorrelation: const PyqCorrelation.constCorrelation(
          matchedPyqCount: 2,
          relevanceScore: 85.0,
          trendAnalysis: 'High frequency in UPSC Prelims',
          keyPyqTopics: ['Ramsar Sites'],
        ),
      );

      final queue = await generateUseCase.execute(quizAnalytics: analytics);
      expect(queue.items.any((i) => i.topic == 'Environment'), isTrue);
    });

    test('ProcessRevisionAttemptUseCase updates item schedule via SM-2',
        () async {
      final queueBefore = await generateUseCase.execute();
      final targetItem = queueBefore.items.first;

      final updated = await processUseCase.execute(targetItem.id, 5);

      expect(updated.id, equals(targetItem.id));
      expect(updated.qualityRating, equals(5));
      expect(updated.lastReviewedAt, isNotNull);
    });

    test('getTopicMastery returns non-empty mastery map overview', () async {
      final mastery = await generateUseCase.getTopicMastery();

      expect(mastery, isNotEmpty);
      expect(mastery.containsKey('Indian Polity'), isTrue);
    });
  });
}
