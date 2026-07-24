import 'package:test/test.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';

void main() {
  group('LearningProfile Immutable Models Unit Tests', () {
    final now = DateTime(2026, 7, 24);

    final sampleTopicMastery = TopicMastery(
      topic: 'Indian Polity',
      subject: 'Polity',
      masteryPercentage: 80.0,
      totalAttempted: 50,
      correctCount: 40,
      retentionScore: 85.0,
      lastPracticedAt: now,
      masteryLevel: 'Proficient',
    );

    final sampleHabit = const StudyHabit(
      peakStudyHour: 20,
      preferredSubject: 'Polity',
      avgSessionDurationMinutes: 30,
      totalSessionsCompleted: 20,
      consistencyScore: 90.0,
      activeDaysCount: 15,
    );

    final sampleStreak = LearningStreak(
      currentStreakDays: 5,
      longestStreakDays: 10,
      lastActivityDate: now,
      streakFreezeCount: 1,
      isStreakActive: true,
    );

    final sampleProfile = LearningProfile(
      userId: 'user_1',
      learnerLevel: 'Consistent Learner',
      overallAccuracy: 75.0,
      totalQuizzesAttempted: 10,
      totalQuestionsAnswered: 100,
      totalStudyTimeMinutes: 300,
      topicMasteries: [sampleTopicMastery],
      studyHabit: sampleHabit,
      streak: sampleStreak,
      weakTopics: ['Environment'],
      lastActiveAt: now,
    );

    test('TopicMastery supports equality and copyWith', () {
      final copy = sampleTopicMastery.copyWith(masteryPercentage: 85.0);

      expect(copy.masteryPercentage, equals(85.0));
      expect(copy.topic, equals('Indian Polity'));
      expect(sampleTopicMastery == copy, isFalse);
      expect(
        sampleTopicMastery ==
            sampleTopicMastery.copyWith(masteryPercentage: 80.0),
        isTrue,
      );
    });

    test('StudyHabit supports equality and copyWith', () {
      final copy = sampleHabit.copyWith(consistencyScore: 95.0);

      expect(copy.consistencyScore, equals(95.0));
      expect(copy.peakStudyHour, equals(20));
      expect(sampleHabit == copy, isFalse);
    });

    test('LearningStreak supports equality and copyWith', () {
      final copy = sampleStreak.copyWith(currentStreakDays: 6);

      expect(copy.currentStreakDays, equals(6));
      expect(copy.longestStreakDays, equals(10));
      expect(sampleStreak == copy, isFalse);
    });

    test('LearningProfile supports equality and copyWith', () {
      final copy = sampleProfile.copyWith(overallAccuracy: 78.0);

      expect(copy.overallAccuracy, equals(78.0));
      expect(copy.userId, equals('user_1'));
      expect(sampleProfile == copy, isFalse);
    });
  });
}
