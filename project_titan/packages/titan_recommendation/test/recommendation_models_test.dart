import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/domain/entities/knowledge_object.dart';
import 'package:knowledge_engine/domain/value_objects/knowledge_type.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('Recommendation Models Unit Tests', () {
    final now = DateTime(2026, 7, 24);

    const sampleReason = RecommendationReason(
      code: 'OVERDUE_RECALL',
      title: 'Active Recall Overdue',
      description: 'Concept is overdue for review',
      weight: 0.95,
    );

    final sampleRecommendation = Recommendation(
      id: 'rec_1',
      title: 'Review Overdue Concept',
      topic: 'Indian Polity',
      actionType: 'Active Recall',
      priority: 'Urgent',
      confidence: 0.95,
      source: 'Revision Engine',
      reasons: const [sampleReason],
      estimatedStudyTimeMinutes: 10,
    );

    test('RecommendationReason equality and copyWith', () {
      final copy = sampleReason.copyWith(weight: 0.99);

      expect(copy.weight, equals(0.99));
      expect(copy.code, equals('OVERDUE_RECALL'));
      expect(sampleReason == copy, isFalse);
    });

    test('Recommendation equality and copyWith', () {
      final copy = sampleRecommendation.copyWith(priority: 'High');

      expect(copy.priority, equals('High'));
      expect(copy.confidence, equals(0.95));
      expect(sampleRecommendation == copy, isFalse);
    });

    test('RecommendationContext immutability and knowledgeObjects support', () {
      final profile = LearningProfile(
        userId: 'user_1',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 75.0,
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
        weakTopics: const ['Environment'],
        lastActiveAt: now,
      );

      final queue = RevisionQueue(
        id: 'q_1',
        userId: 'user_1',
        generatedAt: now,
        items: const [],
        dueTodayCount: 0,
        overdueCount: 0,
        masteredCount: 0,
        summary: 'Empty queue',
      );

      final ko = KnowledgeObject(
        id: 'ko_polity_01',
        type: KnowledgeType.article,
        title: 'Basic Structure Doctrine',
        summary: 'Landmark judicial doctrine',
        source: 'file:///polity.pdf',
        metadata: const {},
        createdAt: now,
        updatedAt: now,
      );

      final context = RecommendationContext(
        profile: profile,
        revisionQueue: queue,
        knowledgeObjects: [ko],
        availableTopics: const ['Indian Polity', 'Environment'],
        generatedAt: now,
      );

      expect(context.availableTopics.length, equals(2));
      expect(context.profile.userId, equals('user_1'));
      expect(context.knowledgeObjects?.length, equals(1));
      expect(context.knowledgeObjects?.first.title,
          equals('Basic Structure Doctrine'));
    });
  });
}
