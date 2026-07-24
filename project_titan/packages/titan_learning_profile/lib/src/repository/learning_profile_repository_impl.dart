import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_revision/titan_revision.dart';
import '../models/learning_profile_models.dart';
import 'learning_profile_repository.dart';

/// Concrete implementation of [LearningProfileRepository] managing learner state.
class LearningProfileRepositoryImpl implements LearningProfileRepository {
  LearningProfile? _currentProfile;

  LearningProfileRepositoryImpl({LearningProfile? initialProfile}) {
    _currentProfile = initialProfile ?? _createDefaultProfile();
  }

  LearningProfile _createDefaultProfile() {
    final now = DateTime.now();

    final polityMastery = TopicMastery(
      topic: 'Indian Polity',
      subject: 'Polity',
      masteryPercentage: 78.5,
      totalAttempted: 45,
      correctCount: 35,
      retentionScore: 82.0,
      lastPracticedAt: now.subtract(const Duration(hours: 3)),
      masteryLevel: 'Proficient',
    );

    final econMastery = TopicMastery(
      topic: 'Indian Economy',
      subject: 'Economy',
      masteryPercentage: 58.0,
      totalAttempted: 40,
      correctCount: 23,
      retentionScore: 60.0,
      lastPracticedAt: now.subtract(const Duration(days: 1)),
      masteryLevel: 'Learning',
    );

    final historyMastery = TopicMastery(
      topic: 'Modern History',
      subject: 'History',
      masteryPercentage: 88.0,
      totalAttempted: 50,
      correctCount: 44,
      retentionScore: 90.0,
      lastPracticedAt: now.subtract(const Duration(days: 2)),
      masteryLevel: 'Master',
    );

    final envMastery = TopicMastery(
      topic: 'Environment & Ecology',
      subject: 'Environment',
      masteryPercentage: 45.0,
      totalAttempted: 30,
      correctCount: 13,
      retentionScore: 48.0,
      lastPracticedAt: now.subtract(const Duration(days: 3)),
      masteryLevel: 'Novice',
    );

    final habit = const StudyHabit(
      peakStudyHour: 20, // 8 PM
      preferredSubject: 'Indian Polity',
      avgSessionDurationMinutes: 28,
      totalSessionsCompleted: 18,
      consistencyScore: 85.0,
      activeDaysCount: 12,
    );

    final streak = LearningStreak(
      currentStreakDays: 7,
      longestStreakDays: 14,
      lastActivityDate: now,
      streakFreezeCount: 1,
      isStreakActive: true,
    );

    return LearningProfile(
      userId: 'user_titan',
      learnerLevel: 'Consistent Learner',
      overallAccuracy: 70.3,
      totalQuizzesAttempted: 18,
      totalQuestionsAnswered: 165,
      totalStudyTimeMinutes: 504,
      topicMasteries: [polityMastery, econMastery, historyMastery, envMastery],
      studyHabit: habit,
      streak: streak,
      weakTopics: ['Environment & Ecology', 'Indian Economy'],
      lastActiveAt: now,
    );
  }

  @override
  Future<LearningProfile> getLearningProfile(
      {String userId = 'user_titan'}) async {
    return _currentProfile ??= _createDefaultProfile();
  }

  @override
  Future<LearningProfile> updateProfileFromQuizAnalytics(
      ResultAnalytics analytics) async {
    final current = await getLearningProfile();
    final now = DateTime.now();

    final updatedMasteries = List<TopicMastery>.from(current.topicMasteries);
    final weakTopics = List<String>.from(current.weakTopics);

    for (final perf in analytics.topicPerformances) {
      final existingIndex =
          updatedMasteries.indexWhere((m) => m.topic == perf.topic);

      final String masteryLevel;
      if (perf.accuracy >= 85.0) {
        masteryLevel = 'Master';
      } else if (perf.accuracy >= 70.0) {
        masteryLevel = 'Proficient';
      } else if (perf.accuracy >= 50.0) {
        masteryLevel = 'Learning';
      } else {
        masteryLevel = 'Novice';
      }

      if (perf.accuracy < 70.0 && !weakTopics.contains(perf.topic)) {
        weakTopics.add(perf.topic);
      } else if (perf.accuracy >= 70.0) {
        weakTopics.remove(perf.topic);
      }

      if (existingIndex >= 0) {
        final existing = updatedMasteries[existingIndex];
        final newTotal = existing.totalAttempted + perf.totalQuestions;
        final newCorrect = existing.correctCount + perf.correctCount;
        final newAccuracy = newTotal > 0
            ? (newCorrect / newTotal) * 100.0
            : existing.masteryPercentage;

        updatedMasteries[existingIndex] = existing.copyWith(
          masteryPercentage: double.parse(newAccuracy.toStringAsFixed(1)),
          totalAttempted: newTotal,
          correctCount: newCorrect,
          retentionScore: double.parse(perf.accuracy.toStringAsFixed(1)),
          lastPracticedAt: now,
          masteryLevel: masteryLevel,
        );
      } else {
        updatedMasteries.add(TopicMastery(
          topic: perf.topic,
          subject: perf.topic,
          masteryPercentage: double.parse(perf.accuracy.toStringAsFixed(1)),
          totalAttempted: perf.totalQuestions,
          correctCount: perf.correctCount,
          retentionScore: double.parse(perf.accuracy.toStringAsFixed(1)),
          lastPracticedAt: now,
          masteryLevel: masteryLevel,
        ));
      }
    }

    final newTotalQuizzes = current.totalQuizzesAttempted + 1;
    final newQuestionsCount =
        current.totalQuestionsAnswered + analytics.scoreMetrics.totalQuestions;
    final newAccuracy =
        (current.overallAccuracy * current.totalQuizzesAttempted +
                analytics.scoreMetrics.percentage) /
            newTotalQuizzes;

    final updatedHabit = current.studyHabit.copyWith(
      totalSessionsCompleted: current.studyHabit.totalSessionsCompleted + 1,
      consistencyScore:
          (current.studyHabit.consistencyScore + 2.0).clamp(0.0, 100.0),
    );

    final updatedStreak = current.streak.copyWith(
      currentStreakDays: current.streak.currentStreakDays + 1,
      longestStreakDays: (current.streak.currentStreakDays + 1) >
              current.streak.longestStreakDays
          ? current.streak.currentStreakDays + 1
          : current.streak.longestStreakDays,
      lastActivityDate: now,
      isStreakActive: true,
    );

    final updatedProfile = current.copyWith(
      overallAccuracy: double.parse(newAccuracy.toStringAsFixed(1)),
      totalQuizzesAttempted: newTotalQuizzes,
      totalQuestionsAnswered: newQuestionsCount,
      totalStudyTimeMinutes: current.totalStudyTimeMinutes + 15,
      topicMasteries: updatedMasteries,
      studyHabit: updatedHabit,
      streak: updatedStreak,
      weakTopics: weakTopics,
      lastActiveAt: now,
    );

    _currentProfile = updatedProfile;
    return updatedProfile;
  }

  @override
  Future<LearningProfile> updateProfileFromRevisionQueue(
      RevisionQueue queue) async {
    final current = await getLearningProfile();
    final now = DateTime.now();

    final updatedMasteries = List<TopicMastery>.from(current.topicMasteries);
    final weakTopics = List<String>.from(current.weakTopics);

    for (final item in queue.items) {
      final idx = updatedMasteries.indexWhere((m) => m.topic == item.topic);
      if (idx >= 0) {
        final existing = updatedMasteries[idx];
        final String newLevel = item.masteryLevel;
        updatedMasteries[idx] = existing.copyWith(
          masteryLevel: newLevel,
          lastPracticedAt: now,
        );

        if (newLevel == 'Master' || newLevel == 'Proficient') {
          weakTopics.remove(item.topic);
        } else if (newLevel == 'Novice' && !weakTopics.contains(item.topic)) {
          weakTopics.add(item.topic);
        }
      }
    }

    final updatedProfile = current.copyWith(
      topicMasteries: updatedMasteries,
      weakTopics: weakTopics,
      lastActiveAt: now,
    );

    _currentProfile = updatedProfile;
    return updatedProfile;
  }

  @override
  Future<void> saveLearningProfile(LearningProfile profile) async {
    _currentProfile = profile;
  }
}
