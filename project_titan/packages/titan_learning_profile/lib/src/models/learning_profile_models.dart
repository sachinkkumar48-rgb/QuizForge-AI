import 'package:meta/meta.dart';

/// Immutable domain model representing a topic's mastery metrics for a learner.
@immutable
class TopicMastery {
  final String topic;
  final String subject;
  final double masteryPercentage;
  final int totalAttempted;
  final int correctCount;
  final double retentionScore;
  final DateTime lastPracticedAt;
  final String masteryLevel; // 'Novice', 'Learning', 'Proficient', 'Master'

  const TopicMastery({
    required this.topic,
    required this.subject,
    required this.masteryPercentage,
    required this.totalAttempted,
    required this.correctCount,
    required this.retentionScore,
    required this.lastPracticedAt,
    required this.masteryLevel,
  });

  TopicMastery copyWith({
    String? topic,
    String? subject,
    double? masteryPercentage,
    int? totalAttempted,
    int? correctCount,
    double? retentionScore,
    DateTime? lastPracticedAt,
    String? masteryLevel,
  }) {
    return TopicMastery(
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      masteryPercentage: masteryPercentage ?? this.masteryPercentage,
      totalAttempted: totalAttempted ?? this.totalAttempted,
      correctCount: correctCount ?? this.correctCount,
      retentionScore: retentionScore ?? this.retentionScore,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      masteryLevel: masteryLevel ?? this.masteryLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicMastery &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          subject == other.subject &&
          masteryPercentage == other.masteryPercentage &&
          totalAttempted == other.totalAttempted &&
          correctCount == other.correctCount &&
          retentionScore == other.retentionScore &&
          lastPracticedAt == other.lastPracticedAt &&
          masteryLevel == other.masteryLevel;

  @override
  int get hashCode => Object.hash(
        topic,
        subject,
        masteryPercentage,
        totalAttempted,
        correctCount,
        retentionScore,
        lastPracticedAt,
        masteryLevel,
      );
}

/// Immutable domain model representing study patterns and habits of a learner.
@immutable
class StudyHabit {
  final int peakStudyHour; // 0 - 23
  final String preferredSubject;
  final int avgSessionDurationMinutes;
  final int totalSessionsCompleted;
  final double consistencyScore; // 0.0 - 100.0
  final int activeDaysCount;

  const StudyHabit({
    required this.peakStudyHour,
    required this.preferredSubject,
    required this.avgSessionDurationMinutes,
    required this.totalSessionsCompleted,
    required this.consistencyScore,
    required this.activeDaysCount,
  });

  StudyHabit copyWith({
    int? peakStudyHour,
    String? preferredSubject,
    int? avgSessionDurationMinutes,
    int? totalSessionsCompleted,
    double? consistencyScore,
    int? activeDaysCount,
  }) {
    return StudyHabit(
      peakStudyHour: peakStudyHour ?? this.peakStudyHour,
      preferredSubject: preferredSubject ?? this.preferredSubject,
      avgSessionDurationMinutes:
          avgSessionDurationMinutes ?? this.avgSessionDurationMinutes,
      totalSessionsCompleted:
          totalSessionsCompleted ?? this.totalSessionsCompleted,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      activeDaysCount: activeDaysCount ?? this.activeDaysCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyHabit &&
          runtimeType == other.runtimeType &&
          peakStudyHour == other.peakStudyHour &&
          preferredSubject == other.preferredSubject &&
          avgSessionDurationMinutes == other.avgSessionDurationMinutes &&
          totalSessionsCompleted == other.totalSessionsCompleted &&
          consistencyScore == other.consistencyScore &&
          activeDaysCount == other.activeDaysCount;

  @override
  int get hashCode => Object.hash(
        peakStudyHour,
        preferredSubject,
        avgSessionDurationMinutes,
        totalSessionsCompleted,
        consistencyScore,
        activeDaysCount,
      );
}

/// Immutable domain model representing learning streak information.
@immutable
class LearningStreak {
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime lastActivityDate;
  final int streakFreezeCount;
  final bool isStreakActive;

  const LearningStreak({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastActivityDate,
    required this.streakFreezeCount,
    required this.isStreakActive,
  });

  LearningStreak copyWith({
    int? currentStreakDays,
    int? longestStreakDays,
    DateTime? lastActivityDate,
    int? streakFreezeCount,
    bool? isStreakActive,
  }) {
    return LearningStreak(
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      streakFreezeCount: streakFreezeCount ?? this.streakFreezeCount,
      isStreakActive: isStreakActive ?? this.isStreakActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningStreak &&
          runtimeType == other.runtimeType &&
          currentStreakDays == other.currentStreakDays &&
          longestStreakDays == other.longestStreakDays &&
          lastActivityDate == other.lastActivityDate &&
          streakFreezeCount == other.streakFreezeCount &&
          isStreakActive == other.isStreakActive;

  @override
  int get hashCode => Object.hash(
        currentStreakDays,
        longestStreakDays,
        lastActivityDate,
        streakFreezeCount,
        isStreakActive,
      );
}

/// Immutable aggregate domain model representing full learner state.
@immutable
class LearningProfile {
  final String userId;
  final String
      learnerLevel; // 'Novice Aspirant', 'Consistent Learner', 'Advanced Scholar', 'UPSC Master'
  final double overallAccuracy;
  final int totalQuizzesAttempted;
  final int totalQuestionsAnswered;
  final int totalStudyTimeMinutes;
  final List<TopicMastery> topicMasteries;
  final StudyHabit studyHabit;
  final LearningStreak streak;
  final List<String> weakTopics;
  final DateTime lastActiveAt;

  LearningProfile({
    required this.userId,
    required this.learnerLevel,
    required this.overallAccuracy,
    required this.totalQuizzesAttempted,
    required this.totalQuestionsAnswered,
    required this.totalStudyTimeMinutes,
    required List<TopicMastery> topicMasteries,
    required this.studyHabit,
    required this.streak,
    required List<String> weakTopics,
    required this.lastActiveAt,
  })  : topicMasteries = List<TopicMastery>.unmodifiable(topicMasteries),
        weakTopics = List<String>.unmodifiable(weakTopics);

  LearningProfile copyWith({
    String? userId,
    String? learnerLevel,
    double? overallAccuracy,
    int? totalQuizzesAttempted,
    int? totalQuestionsAnswered,
    int? totalStudyTimeMinutes,
    List<TopicMastery>? topicMasteries,
    StudyHabit? studyHabit,
    LearningStreak? streak,
    List<String>? weakTopics,
    DateTime? lastActiveAt,
  }) {
    return LearningProfile(
      userId: userId ?? this.userId,
      learnerLevel: learnerLevel ?? this.learnerLevel,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      totalQuizzesAttempted:
          totalQuizzesAttempted ?? this.totalQuizzesAttempted,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalStudyTimeMinutes:
          totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
      topicMasteries: topicMasteries ?? this.topicMasteries,
      studyHabit: studyHabit ?? this.studyHabit,
      streak: streak ?? this.streak,
      weakTopics: weakTopics ?? this.weakTopics,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          learnerLevel == other.learnerLevel &&
          overallAccuracy == other.overallAccuracy &&
          totalQuizzesAttempted == other.totalQuizzesAttempted &&
          totalQuestionsAnswered == other.totalQuestionsAnswered &&
          totalStudyTimeMinutes == other.totalStudyTimeMinutes &&
          studyHabit == other.studyHabit &&
          streak == other.streak &&
          lastActiveAt == other.lastActiveAt &&
          _listEquals(topicMasteries, other.topicMasteries) &&
          _listEquals(weakTopics, other.weakTopics);

  @override
  int get hashCode => Object.hash(
        userId,
        learnerLevel,
        overallAccuracy,
        totalQuizzesAttempted,
        totalQuestionsAnswered,
        totalStudyTimeMinutes,
        studyHabit,
        streak,
        lastActiveAt,
        Object.hashAll(topicMasteries),
        Object.hashAll(weakTopics),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
