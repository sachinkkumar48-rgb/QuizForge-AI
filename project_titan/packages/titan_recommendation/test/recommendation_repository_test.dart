import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('RecommendationRepository & GenerateRecommendationsUseCase Tests', () {
    late RecommendationEngine engine;
    late RecommendationRepository repository;
    late GenerateRecommendationsUseCase generateUseCase;

    final now = DateTime(2026, 7, 24);

    setUp(() {
      engine = const RecommendationEngine();
      repository = RecommendationRepositoryImpl(engine: engine);
      generateUseCase = GenerateRecommendationsUseCase(repository);
    });

    test('RecommendationRepository generates and caches recommendations',
        () async {
      final profile = LearningProfile(
        userId: 'user_repo',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 70.0,
        totalQuizzesAttempted: 10,
        totalQuestionsAnswered: 100,
        totalStudyTimeMinutes: 300,
        topicMasteries: const [],
        studyHabit: const StudyHabit(
          peakStudyHour: 20,
          preferredSubject: 'Polity',
          avgSessionDurationMinutes: 30,
          totalSessionsCompleted: 10,
          consistencyScore: 80.0,
          activeDaysCount: 10,
        ),
        streak: LearningStreak(
          currentStreakDays: 5,
          longestStreakDays: 10,
          lastActivityDate: now,
          streakFreezeCount: 0,
          isStreakActive: true,
        ),
        weakTopics: const ['Economy'],
        lastActiveAt: now,
      );

      final queue = RevisionQueue(
        id: 'q_repo',
        userId: 'user_repo',
        generatedAt: now,
        items: const [],
        dueTodayCount: 0,
        overdueCount: 0,
        masteredCount: 0,
        summary: 'Clean',
      );

      final context = RecommendationContext(
        profile: profile,
        revisionQueue: queue,
        availableTopics: const ['Economy'],
        generatedAt: now,
      );

      final generated = await generateUseCase.execute(context);
      final cached = await generateUseCase.getLatest();

      expect(generated, equals(cached));
      expect(generated, isNotEmpty);
      expect(generated.first.topic, equals('Economy'));
    });
  });
}
