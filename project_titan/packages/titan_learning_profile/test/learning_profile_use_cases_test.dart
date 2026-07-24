import 'package:test/test.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('LearningProfile Repository & Use Cases Unit Tests', () {
    late LearningProfileRepository repository;
    late GetLearningProfileUseCase getProfileUseCase;
    late UpdateLearningProfileUseCase updateProfileUseCase;

    setUp(() {
      repository = LearningProfileRepositoryImpl();
      getProfileUseCase = GetLearningProfileUseCase(repository);
      updateProfileUseCase = UpdateLearningProfileUseCase(repository);
    });

    test('GetLearningProfileUseCase returns initial seeded profile', () async {
      final profile = await getProfileUseCase.execute();

      expect(profile.userId, equals('user_titan'));
      expect(profile.topicMasteries, isNotEmpty);
      expect(profile.studyHabit.consistencyScore, greaterThan(0));
      expect(profile.streak.currentStreakDays, greaterThan(0));
    });

    test('UpdateLearningProfileUseCase updates state from ResultAnalytics',
        () async {
      final now = DateTime.now();

      final quizResult = QuizResult(
        quizId: 'session_test_01',
        attempted: 10,
        correct: 8,
        wrong: 2,
        unanswered: 0,
        score: 16.0,
        maxScore: 20.0,
        percentage: 80.0,
      );

      final analytics = ResultAnalytics(
        quizResult: quizResult,
        scoreMetrics: const ScoreMetrics(
          scoreObtained: 16.0,
          maxScore: 20.0,
          percentage: 80.0,
          totalQuestions: 10,
          correctCount: 8,
          wrongCount: 2,
          unansweredCount: 0,
          timeTaken: Duration(minutes: 10),
          accuracy: 80.0,
          percentileRank: 85.0,
          status: 'Pass',
        ),
        topicPerformances: const [
          TopicPerformance(
            topic: 'Indian Polity',
            totalQuestions: 10,
            correctCount: 8,
            wrongCount: 2,
            accuracy: 80.0,
            masteryLevel: 'Proficient',
          ),
        ],
        mistakeAnalysis: MistakeAnalysis(
          conceptualErrors: 1,
          sillyErrors: 1,
          timePressureErrors: 0,
          skippedCount: 0,
          keyMistakeInsights: const ['Review Writs'],
        ),
        revisionRecommendation: RevisionRecommendation(
          scheduledDate: now.add(const Duration(days: 2)),
          priorityLevel: 'Medium',
          recommendedTopics: const ['Indian Polity'],
          suggestedResources: const ['NCERT Polity'],
        ),
        pyqCorrelation: PyqCorrelation(
          matchedPyqCount: 5,
          relevanceScore: 85.0,
          trendAnalysis: 'High overlap with 2021-2023 PYQs',
          keyPyqTopics: const ['Art 32'],
        ),
        mentorFeedback: MentorFeedback(
          summary: 'Good performance in Polity.',
          strengths: const ['Fundamental Rights'],
          weakAreas: const ['DPSP'],
          recommendation: 'Solve 10 questions daily',
          actionPlan: const ['Solve 10 questions daily'],
        ),
      );

      final updated = await updateProfileUseCase.fromQuizAnalytics(analytics);

      expect(updated.totalQuizzesAttempted, equals(19));
      expect(updated.topicMasteries.any((t) => t.topic == 'Indian Polity'),
          isTrue);
    });

    test('UpdateLearningProfileUseCase updates state from RevisionQueue',
        () async {
      final now = DateTime.now();

      final revisionItem = RevisionItem(
        id: 'rev_polity_01',
        topic: 'Indian Polity',
        nextReviewDate: now,
        lastReviewedAt: now,
        masteryLevel: 'Master',
      );

      final queue = RevisionQueue(
        id: 'q_test',
        userId: 'user_titan',
        generatedAt: now,
        items: [revisionItem],
        dueTodayCount: 1,
        overdueCount: 0,
        masteredCount: 1,
        summary: 'Queue up to date',
      );

      final updated = await updateProfileUseCase.fromRevisionQueue(queue);

      final polity =
          updated.topicMasteries.firstWhere((t) => t.topic == 'Indian Polity');
      expect(polity.masteryLevel, equals('Master'));
    });
  });
}
