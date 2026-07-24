import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/domain/entities/knowledge_object.dart';
import 'package:knowledge_engine/domain/value_objects/knowledge_type.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('Recommendation Engine & Rules Unit Tests', () {
    late RecommendationEngine engine;
    late RecommendationRepository repository;
    late GenerateRecommendationsUseCase generateUseCase;

    final now = DateTime(2026, 7, 24);

    setUp(() {
      engine = const RecommendationEngine();
      repository = RecommendationRepositoryImpl(engine: engine);
      generateUseCase = GenerateRecommendationsUseCase(repository);
    });

    test(
        'RecommendationEngine generates Urgent recommendation for overdue revision item',
        () async {
      final overdueItem = RevisionItem(
        id: 'rev_polity_01',
        topic: 'Indian Polity',
        subtopic: 'Fundamental Rights & Writs',
        nextReviewDate: now.subtract(const Duration(hours: 5)),
        lastReviewedAt: now.subtract(const Duration(days: 2)),
        qualityRating: 2,
        priority: 'Urgent',
      );

      final queue = RevisionQueue(
        id: 'q_overdue',
        userId: 'user_titan',
        generatedAt: now,
        items: [overdueItem],
        dueTodayCount: 1,
        overdueCount: 1,
        masteredCount: 0,
        summary: 'Overdue concepts present',
      );

      final profile = LearningProfile(
        userId: 'user_titan',
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
        weakTopics: const ['Indian Polity'],
        lastActiveAt: now,
      );

      final context = RecommendationContext(
        profile: profile,
        revisionQueue: queue,
        availableTopics: const ['Indian Polity'],
        generatedAt: now,
      );

      final recommendations = await generateUseCase.execute(context);

      expect(recommendations, isNotEmpty);
      final topRec = recommendations.first;
      expect(topRec.priority, equals('Urgent'));
      expect(topRec.confidence, equals(0.95));
      expect(topRec.source, equals('Revision Engine'));
      expect(topRec.reasons.any((r) => r.code == 'OVERDUE_RECALL'), isTrue);
      expect(topRec.estimatedStudyTimeMinutes, greaterThan(0));
    });

    test(
        'RecommendationEngine generates High priority for LearningProfile weak topics',
        () async {
      final queue = RevisionQueue(
        id: 'q_empty',
        userId: 'user_titan',
        generatedAt: now,
        items: const [],
        dueTodayCount: 0,
        overdueCount: 0,
        masteredCount: 0,
        summary: 'Queue up to date',
      );

      final profile = LearningProfile(
        userId: 'user_titan',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 65.0,
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
        weakTopics: const ['Environment & Ecology'],
        lastActiveAt: now,
      );

      final context = RecommendationContext(
        profile: profile,
        revisionQueue: queue,
        availableTopics: const ['Environment & Ecology'],
        generatedAt: now,
      );

      final recommendations = await generateUseCase.execute(context);

      expect(recommendations, isNotEmpty);
      final weakRec =
          recommendations.firstWhere((r) => r.topic == 'Environment & Ecology');
      expect(weakRec.priority, equals('High'));
      expect(weakRec.source, equals('Learning Profile'));
      expect(weakRec.reasons.first.code, equals('WEAK_AREA_DEEP_DIVE'));
    });

    test('RecommendationEngine evaluates Analytics Engine quiz mistakes',
        () async {
      final queue = RevisionQueue(
        id: 'q_empty',
        userId: 'user_titan',
        generatedAt: now,
        items: const [],
        dueTodayCount: 0,
        overdueCount: 0,
        masteredCount: 0,
        summary: 'Empty',
      );

      final profile = LearningProfile(
        userId: 'user_titan',
        learnerLevel: 'Beginner',
        overallAccuracy: 50.0,
        totalQuizzesAttempted: 5,
        totalQuestionsAnswered: 50,
        totalStudyTimeMinutes: 120,
        topicMasteries: const [],
        studyHabit: const StudyHabit(
          peakStudyHour: 10,
          preferredSubject: 'History',
          avgSessionDurationMinutes: 20,
          totalSessionsCompleted: 5,
          consistencyScore: 60.0,
          activeDaysCount: 5,
        ),
        streak: LearningStreak(
          currentStreakDays: 2,
          longestStreakDays: 5,
          lastActivityDate: now,
          streakFreezeCount: 0,
          isStreakActive: true,
        ),
        weakTopics: const [],
        lastActiveAt: now,
      );

      final quizResult = QuizResult(
        quizId: 'quiz_hist_01',
        attempted: 10,
        correct: 4,
        wrong: 6,
        unanswered: 0,
        score: 4.0,
        maxScore: 10.0,
        percentage: 40.0,
      );

      final analytics = ResultAnalytics(
        quizResult: quizResult,
        scoreMetrics: const ScoreMetrics(
          scoreObtained: 4.0,
          maxScore: 10.0,
          percentage: 40.0,
          totalQuestions: 10,
          correctCount: 4,
          wrongCount: 6,
          unansweredCount: 0,
          timeTaken: Duration(seconds: 450),
          accuracy: 40.0,
          percentileRank: 50.0,
          status: 'Completed',
        ),
        topicPerformances: const [
          TopicPerformance(
            topic: 'Ancient History',
            totalQuestions: 10,
            correctCount: 4,
            wrongCount: 6,
            accuracy: 40.0,
            masteryLevel: 'Needs Improvement',
          ),
        ],
        mistakeAnalysis: const MistakeAnalysis.constAnalysis(
          conceptualErrors: 4,
          sillyErrors: 2,
          timePressureErrors: 0,
          skippedCount: 0,
          keyMistakeInsights: ['Review Indus Valley timeline'],
        ),
        mentorFeedback: const MentorFeedback.constFeedback(
          summary: 'Focus on Ancient History',
          strengths: [],
          weakAreas: ['Ancient History'],
          recommendation: 'Deep dive into Indus Valley',
          actionPlan: ['Read chapter 3'],
        ),
        revisionRecommendation: RevisionRecommendation.constRecommendation(
          recommendedTopics: const ['Ancient History'],
          priorityLevel: 'High',
          scheduledDate: now,
          suggestedResources: const [],
        ),
        pyqCorrelation: const PyqCorrelation.constCorrelation(
          matchedPyqCount: 8,
          relevanceScore: 0.8,
          trendAnalysis: 'High yield',
          keyPyqTopics: ['Indus Valley Civilization'],
        ),
      );

      final context = RecommendationContext(
        profile: profile,
        revisionQueue: queue,
        latestAnalytics: analytics,
        availableTopics: const ['Ancient History'],
        generatedAt: now,
      );

      final recs = await generateUseCase.execute(context);
      expect(recs, isNotEmpty);

      final analyticsRec =
          recs.firstWhere((r) => r.source == 'Analytics Engine');
      expect(analyticsRec.priority, equals('High'));
      expect(analyticsRec.topic, equals('Ancient History'));
      expect(analyticsRec.reasons.first.code, equals('RECENT_QUIZ_MISTAKE'));
    });

    test('RecommendationEngine evaluates Knowledge Engine objects & PYQ trends',
        () async {
      final queue = RevisionQueue(
        id: 'q_empty',
        userId: 'user_titan',
        generatedAt: now,
        items: const [],
        dueTodayCount: 0,
        overdueCount: 0,
        masteredCount: 0,
        summary: 'Empty',
      );

      final profile = LearningProfile(
        userId: 'user_titan',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 75.0,
        totalQuizzesAttempted: 10,
        totalQuestionsAnswered: 100,
        totalStudyTimeMinutes: 200,
        topicMasteries: const [],
        studyHabit: const StudyHabit(
          peakStudyHour: 15,
          preferredSubject: 'Economy',
          avgSessionDurationMinutes: 30,
          totalSessionsCompleted: 10,
          consistencyScore: 85.0,
          activeDaysCount: 10,
        ),
        streak: LearningStreak(
          currentStreakDays: 7,
          longestStreakDays: 14,
          lastActivityDate: now,
          streakFreezeCount: 0,
          isStreakActive: true,
        ),
        weakTopics: const [],
        lastActiveAt: now,
      );

      final ko = KnowledgeObject(
        id: 'ko_econ_01',
        type: KnowledgeType.article,
        title: 'Monetary Policy & Repo Rate',
        summary: 'RBI repo rate and monetary policy stance',
        source: 'file:///economy.pdf',
        metadata: const {},
        createdAt: now,
        updatedAt: now,
      );

      final context = RecommendationContext(
        profile: profile,
        revisionQueue: queue,
        knowledgeObjects: [ko],
        availableTopics: const ['Indian Economy'],
        generatedAt: now,
      );

      final recs = await generateUseCase.execute(context);
      expect(recs, isNotEmpty);

      final keRec = recs.firstWhere((r) => r.source == 'Knowledge Engine');
      expect(keRec.topic, equals('Monetary Policy & Repo Rate'));
      expect(keRec.priority, equals('High'));
      expect(keRec.reasons.first.code, equals('KNOWLEDGE_GRAPH_PRIORITY'));
    });

    test(
        'RecommendationEngine sorts recommendations by priority order and confidence',
        () async {
      final overdueItem = RevisionItem(
        id: 'rev_polity_01',
        topic: 'Indian Polity',
        nextReviewDate: now.subtract(const Duration(hours: 2)),
        lastReviewedAt: now.subtract(const Duration(days: 3)),
        qualityRating: 1,
        priority: 'Urgent',
      );

      final queue = RevisionQueue(
        id: 'q_1',
        userId: 'user_1',
        generatedAt: now,
        items: [overdueItem],
        dueTodayCount: 1,
        overdueCount: 1,
        masteredCount: 0,
        summary: '1 overdue',
      );

      final profile = LearningProfile(
        userId: 'user_1',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 60.0,
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
        weakTopics: const ['Geography'],
        lastActiveAt: now,
      );

      final context = RecommendationContext(
        profile: profile,
        revisionQueue: queue,
        availableTopics: const ['Indian Polity', 'Geography'],
        generatedAt: now,
      );

      final recs = await generateUseCase.execute(context);
      expect(recs.length, greaterThanOrEqualTo(2));
      expect(recs[0].priority, equals('Urgent'));
      expect(recs[1].priority, equals('High'));
    });
  });
}
