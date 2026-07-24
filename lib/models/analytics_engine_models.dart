enum ConfidenceLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case ConfidenceLevel.low:
        return 'Low Confidence (< 5 questions)';
      case ConfidenceLevel.medium:
        return 'Medium Confidence (5-15 questions)';
      case ConfidenceLevel.high:
        return 'High Confidence (> 15 questions)';
    }
  }

  static ConfidenceLevel fromAttemptCount(int count) {
    if (count < 5) return ConfidenceLevel.low;
    if (count <= 15) return ConfidenceLevel.medium;
    return ConfidenceLevel.high;
  }
}

/// Represents a detected weak area (subject, topic, difficulty, or year) with confidence rating.
class WeakAreaInsight {
  final String dimension; // 'subject', 'topic', 'difficulty', 'year'
  final String name;
  final double accuracyPercent;
  final int attemptedCount;
  final int correctCount;
  final ConfidenceLevel confidenceLevel;
  final String recommendation;

  WeakAreaInsight({
    required this.dimension,
    required this.name,
    required this.accuracyPercent,
    required this.attemptedCount,
    required this.correctCount,
    required this.confidenceLevel,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'name': name,
        'accuracyPercent': accuracyPercent,
        'attemptedCount': attemptedCount,
        'correctCount': correctCount,
        'confidenceLevel': confidenceLevel.name,
        'recommendation': recommendation,
      };

  factory WeakAreaInsight.fromJson(Map<String, dynamic> json) =>
      WeakAreaInsight(
        dimension: json['dimension'] as String? ?? 'subject',
        name: json['name'] as String? ?? '',
        accuracyPercent: (json['accuracyPercent'] as num? ?? 0.0).toDouble(),
        attemptedCount: json['attemptedCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        confidenceLevel: ConfidenceLevel.values.byName(
          json['confidenceLevel'] as String? ?? 'low',
        ),
        recommendation: json['recommendation'] as String? ?? '',
      );
}

/// Generalized model for tracking accuracy breakdowns across dimensions.
class EntityAccuracy {
  final String key;
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctQuestions;
  final int totalTimeSpentSeconds;

  EntityAccuracy({
    required this.key,
    required this.totalQuestions,
    required this.attemptedQuestions,
    required this.correctQuestions,
    this.totalTimeSpentSeconds = 0,
  });

  double get accuracyPercent => attemptedQuestions == 0
      ? 0.0
      : (correctQuestions / attemptedQuestions) * 100;

  double get averageTimeSeconds => attemptedQuestions == 0
      ? 0.0
      : totalTimeSpentSeconds / attemptedQuestions;

  Map<String, dynamic> toJson() => {
        'key': key,
        'totalQuestions': totalQuestions,
        'attemptedQuestions': attemptedQuestions,
        'correctQuestions': correctQuestions,
        'totalTimeSpentSeconds': totalTimeSpentSeconds,
      };

  factory EntityAccuracy.fromJson(Map<String, dynamic> json) => EntityAccuracy(
        key: json['key'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedQuestions: json['attemptedQuestions'] as int? ?? 0,
        correctQuestions: json['correctQuestions'] as int? ?? 0,
        totalTimeSpentSeconds: json['totalTimeSpentSeconds'] as int? ?? 0,
      );
}

/// Historical snapshot for tracking trends over time.
class AnalyticsSnapshot {
  final String snapshotId;
  final DateTime timestamp;
  final double overallAccuracy;
  final int questionsSolved;
  final int currentStreak;
  final List<String> weakSubjects;
  final List<String> strongSubjects;

  AnalyticsSnapshot({
    required this.snapshotId,
    DateTime? timestamp,
    required this.overallAccuracy,
    required this.questionsSolved,
    required this.currentStreak,
    required this.weakSubjects,
    required this.strongSubjects,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'snapshotId': snapshotId,
        'timestamp': timestamp.toIso8601String(),
        'overallAccuracy': overallAccuracy,
        'questionsSolved': questionsSolved,
        'currentStreak': currentStreak,
        'weakSubjects': weakSubjects,
        'strongSubjects': strongSubjects,
      };

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) =>
      AnalyticsSnapshot(
        snapshotId: json['snapshotId'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : DateTime.now().toUtc(),
        overallAccuracy: (json['overallAccuracy'] as num? ?? 0.0).toDouble(),
        questionsSolved: json['questionsSolved'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        weakSubjects: json['weakSubjects'] != null
            ? List<String>.from(json['weakSubjects'] as List)
            : const [],
        strongSubjects: json['strongSubjects'] != null
            ? List<String>.from(json['strongSubjects'] as List)
            : const [],
      );
}

/// Comprehensive model containing all 16 tracked learning metrics.
class LearningInsightsModel {
  final double overallAccuracy;
  final Map<String, EntityAccuracy> subjectAccuracy;
  final Map<String, EntityAccuracy> topicAccuracy;
  final Map<int, EntityAccuracy> yearAccuracy;
  final Map<String, EntityAccuracy> difficultyAccuracy;
  final double averageTimePerQuestionSeconds;
  final double averageQuizScore;
  final int dailyQuestionsSolved;
  final int weeklyQuestionsSolved;
  final int monthlyQuestionsSolved;
  final int currentStreak;
  final int longestStreak;
  final double revisionCompletionPercent;
  final int bookmarkCount;
  final int incorrectQuestionCount;
  final Map<String, int> questionAttemptFrequency;
  final List<WeakAreaInsight> weakAreaInsights;
  final List<String> strongSubjects;
  final List<String> weakSubjects;

  LearningInsightsModel({
    required this.overallAccuracy,
    required this.subjectAccuracy,
    required this.topicAccuracy,
    required this.yearAccuracy,
    required this.difficultyAccuracy,
    required this.averageTimePerQuestionSeconds,
    required this.averageQuizScore,
    required this.dailyQuestionsSolved,
    required this.weeklyQuestionsSolved,
    required this.monthlyQuestionsSolved,
    required this.currentStreak,
    required this.longestStreak,
    required this.revisionCompletionPercent,
    required this.bookmarkCount,
    required this.incorrectQuestionCount,
    required this.questionAttemptFrequency,
    required this.weakAreaInsights,
    required this.strongSubjects,
    required this.weakSubjects,
  });
}
