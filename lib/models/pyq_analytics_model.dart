class PyqSubjectAccuracy {
  final String subject;
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctQuestions;

  PyqSubjectAccuracy({
    required this.subject,
    required this.totalQuestions,
    required this.attemptedQuestions,
    required this.correctQuestions,
  });

  double get accuracyPercent => attemptedQuestions == 0
      ? 0.0
      : (correctQuestions / attemptedQuestions) * 100;

  double get completionPercent =>
      totalQuestions == 0 ? 0.0 : (attemptedQuestions / totalQuestions) * 100;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'totalQuestions': totalQuestions,
        'attemptedQuestions': attemptedQuestions,
        'correctQuestions': correctQuestions,
      };

  factory PyqSubjectAccuracy.fromJson(Map<String, dynamic> json) =>
      PyqSubjectAccuracy(
        subject: json['subject'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedQuestions: json['attemptedQuestions'] as int? ?? 0,
        correctQuestions: json['correctQuestions'] as int? ?? 0,
      );
}

class PyqYearAccuracy {
  final int year;
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctQuestions;

  PyqYearAccuracy({
    required this.year,
    required this.totalQuestions,
    required this.attemptedQuestions,
    required this.correctQuestions,
  });

  double get accuracyPercent => attemptedQuestions == 0
      ? 0.0
      : (correctQuestions / attemptedQuestions) * 100;

  Map<String, dynamic> toJson() => {
        'year': year,
        'totalQuestions': totalQuestions,
        'attemptedQuestions': attemptedQuestions,
        'correctQuestions': correctQuestions,
      };

  factory PyqYearAccuracy.fromJson(Map<String, dynamic> json) =>
      PyqYearAccuracy(
        year: json['year'] as int? ?? 2024,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedQuestions: json['attemptedQuestions'] as int? ?? 0,
        correctQuestions: json['correctQuestions'] as int? ?? 0,
      );
}

class PyqTopicAccuracy {
  final String topic;
  final String subject;
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctQuestions;

  PyqTopicAccuracy({
    required this.topic,
    required this.subject,
    required this.totalQuestions,
    required this.attemptedQuestions,
    required this.correctQuestions,
  });

  double get accuracyPercent => attemptedQuestions == 0
      ? 0.0
      : (correctQuestions / attemptedQuestions) * 100;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'subject': subject,
        'totalQuestions': totalQuestions,
        'attemptedQuestions': attemptedQuestions,
        'correctQuestions': correctQuestions,
      };

  factory PyqTopicAccuracy.fromJson(Map<String, dynamic> json) =>
      PyqTopicAccuracy(
        topic: json['topic'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedQuestions: json['attemptedQuestions'] as int? ?? 0,
        correctQuestions: json['correctQuestions'] as int? ?? 0,
      );
}

class PyqDifficultyAccuracy {
  final String difficulty;
  final int totalQuestions;
  final int attemptedQuestions;
  final int correctQuestions;

  PyqDifficultyAccuracy({
    required this.difficulty,
    required this.totalQuestions,
    required this.attemptedQuestions,
    required this.correctQuestions,
  });

  double get accuracyPercent => attemptedQuestions == 0
      ? 0.0
      : (correctQuestions / attemptedQuestions) * 100;

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
        'totalQuestions': totalQuestions,
        'attemptedQuestions': attemptedQuestions,
        'correctQuestions': correctQuestions,
      };

  factory PyqDifficultyAccuracy.fromJson(Map<String, dynamic> json) =>
      PyqDifficultyAccuracy(
        difficulty: json['difficulty'] as String? ?? 'Medium',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedQuestions: json['attemptedQuestions'] as int? ?? 0,
        correctQuestions: json['correctQuestions'] as int? ?? 0,
      );
}

class AccuracyMetrics {
  final double overallAccuracyPercent;
  final double overallCompletionPercent;
  final int totalAttempted;
  final int totalCorrect;
  final int totalIncorrect;

  AccuracyMetrics({
    required this.overallAccuracyPercent,
    required this.overallCompletionPercent,
    required this.totalAttempted,
    required this.totalCorrect,
    required this.totalIncorrect,
  });

  Map<String, dynamic> toJson() => {
        'overallAccuracyPercent': overallAccuracyPercent,
        'overallCompletionPercent': overallCompletionPercent,
        'totalAttempted': totalAttempted,
        'totalCorrect': totalCorrect,
        'totalIncorrect': totalIncorrect,
      };

  factory AccuracyMetrics.fromJson(Map<String, dynamic> json) =>
      AccuracyMetrics(
        overallAccuracyPercent:
            (json['overallAccuracyPercent'] as num? ?? 0.0).toDouble(),
        overallCompletionPercent:
            (json['overallCompletionPercent'] as num? ?? 0.0).toDouble(),
        totalAttempted: json['totalAttempted'] as int? ?? 0,
        totalCorrect: json['totalCorrect'] as int? ?? 0,
        totalIncorrect: json['totalIncorrect'] as int? ?? 0,
      );
}

class SpeedMetrics {
  final double avgSecondsPerQuestion;
  final int totalTimeSpentSeconds;
  final String speedStatus;

  SpeedMetrics({
    required this.avgSecondsPerQuestion,
    required this.totalTimeSpentSeconds,
    required this.speedStatus,
  });

  Map<String, dynamic> toJson() => {
        'avgSecondsPerQuestion': avgSecondsPerQuestion,
        'totalTimeSpentSeconds': totalTimeSpentSeconds,
        'speedStatus': speedStatus,
      };

  factory SpeedMetrics.fromJson(Map<String, dynamic> json) => SpeedMetrics(
        avgSecondsPerQuestion:
            (json['avgSecondsPerQuestion'] as num? ?? 0.0).toDouble(),
        totalTimeSpentSeconds: json['totalTimeSpentSeconds'] as int? ?? 0,
        speedStatus: json['speedStatus'] as String? ?? 'Optimal',
      );
}

class ConsistencyMetrics {
  final double consistencyScorePercent;
  final int totalActiveDays;
  final int activeDaysThisMonth;

  ConsistencyMetrics({
    required this.consistencyScorePercent,
    required this.totalActiveDays,
    required this.activeDaysThisMonth,
  });

  Map<String, dynamic> toJson() => {
        'consistencyScorePercent': consistencyScorePercent,
        'totalActiveDays': totalActiveDays,
        'activeDaysThisMonth': activeDaysThisMonth,
      };

  factory ConsistencyMetrics.fromJson(Map<String, dynamic> json) =>
      ConsistencyMetrics(
        consistencyScorePercent:
            (json['consistencyScorePercent'] as num? ?? 0.0).toDouble(),
        totalActiveDays: json['totalActiveDays'] as int? ?? 0,
        activeDaysThisMonth: json['activeDaysThisMonth'] as int? ?? 0,
      );
}

class RetentionMetrics {
  final int repeatAttemptCount;
  final int repeatCorrectCount;
  final double retentionPercent;

  RetentionMetrics({
    required this.repeatAttemptCount,
    required this.repeatCorrectCount,
    required this.retentionPercent,
  });

  Map<String, dynamic> toJson() => {
        'repeatAttemptCount': repeatAttemptCount,
        'repeatCorrectCount': repeatCorrectCount,
        'retentionPercent': retentionPercent,
      };

  factory RetentionMetrics.fromJson(Map<String, dynamic> json) =>
      RetentionMetrics(
        repeatAttemptCount: json['repeatAttemptCount'] as int? ?? 0,
        repeatCorrectCount: json['repeatCorrectCount'] as int? ?? 0,
        retentionPercent: (json['retentionPercent'] as num? ?? 0.0).toDouble(),
      );
}

class StreakMetrics {
  final int currentDailyStreak;
  final int maxDailyStreak;
  final int currentWeeklyStreak;
  final int maxWeeklyStreak;

  StreakMetrics({
    required this.currentDailyStreak,
    required this.maxDailyStreak,
    required this.currentWeeklyStreak,
    required this.maxWeeklyStreak,
  });

  Map<String, dynamic> toJson() => {
        'currentDailyStreak': currentDailyStreak,
        'maxDailyStreak': maxDailyStreak,
        'currentWeeklyStreak': currentWeeklyStreak,
        'maxWeeklyStreak': maxWeeklyStreak,
      };

  factory StreakMetrics.fromJson(Map<String, dynamic> json) => StreakMetrics(
        currentDailyStreak: json['currentDailyStreak'] as int? ?? 0,
        maxDailyStreak: json['maxDailyStreak'] as int? ?? 0,
        currentWeeklyStreak: json['currentWeeklyStreak'] as int? ?? 0,
        maxWeeklyStreak: json['maxWeeklyStreak'] as int? ?? 0,
      );
}

class RevisionMetrics {
  final int incorrectBankSize;
  final int bookmarkedCount;
  final int revisedBookmarkedCount;
  final double weakAreaMasteryPercent;

  RevisionMetrics({
    required this.incorrectBankSize,
    required this.bookmarkedCount,
    required this.revisedBookmarkedCount,
    required this.weakAreaMasteryPercent,
  });

  Map<String, dynamic> toJson() => {
        'incorrectBankSize': incorrectBankSize,
        'bookmarkedCount': bookmarkedCount,
        'revisedBookmarkedCount': revisedBookmarkedCount,
        'weakAreaMasteryPercent': weakAreaMasteryPercent,
      };

  factory RevisionMetrics.fromJson(Map<String, dynamic> json) =>
      RevisionMetrics(
        incorrectBankSize: json['incorrectBankSize'] as int? ?? 0,
        bookmarkedCount: json['bookmarkedCount'] as int? ?? 0,
        revisedBookmarkedCount: json['revisedBookmarkedCount'] as int? ?? 0,
        weakAreaMasteryPercent:
            (json['weakAreaMasteryPercent'] as num? ?? 0.0).toDouble(),
      );
}

class MonthlyProgressMetrics {
  final Map<String, int> monthlyAttemptsMap;
  final Map<String, double> monthlyAccuracyMap;

  MonthlyProgressMetrics({
    required this.monthlyAttemptsMap,
    required this.monthlyAccuracyMap,
  });

  Map<String, dynamic> toJson() => {
        'monthlyAttemptsMap': monthlyAttemptsMap,
        'monthlyAccuracyMap': monthlyAccuracyMap,
      };

  factory MonthlyProgressMetrics.fromJson(Map<String, dynamic> json) =>
      MonthlyProgressMetrics(
        monthlyAttemptsMap:
            (json['monthlyAttemptsMap'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, v as int)) ??
                {},
        monthlyAccuracyMap:
            (json['monthlyAccuracyMap'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
                {},
      );
}

class PyqAnalyticsModel {
  final int totalQuestions;
  final int totalAttempted;
  final int totalCorrect;
  final int totalBookmarked;
  final int totalIncorrectBank;
  final List<PyqSubjectAccuracy> subjectMetrics;
  final List<PyqYearAccuracy> yearMetrics;
  final List<PyqTopicAccuracy> topicMetrics;
  final List<PyqDifficultyAccuracy> difficultyMetrics;
  final List<String> weakSubjects;
  final List<String> strongSubjects;

  // New analytics engine dimensions
  final AccuracyMetrics accuracyMetrics;
  final SpeedMetrics speedMetrics;
  final ConsistencyMetrics consistencyMetrics;
  final RetentionMetrics retentionMetrics;
  final StreakMetrics streakMetrics;
  final RevisionMetrics revisionMetrics;
  final MonthlyProgressMetrics monthlyMetrics;

  PyqAnalyticsModel({
    required this.totalQuestions,
    required this.totalAttempted,
    required this.totalCorrect,
    required this.totalBookmarked,
    required this.totalIncorrectBank,
    required this.subjectMetrics,
    required this.yearMetrics,
    required this.topicMetrics,
    required this.difficultyMetrics,
    required this.weakSubjects,
    required this.strongSubjects,
    required this.accuracyMetrics,
    required this.speedMetrics,
    required this.consistencyMetrics,
    required this.retentionMetrics,
    required this.streakMetrics,
    required this.revisionMetrics,
    required this.monthlyMetrics,
  });

  double get overallAccuracyPercent =>
      totalAttempted == 0 ? 0.0 : (totalCorrect / totalAttempted) * 100;

  double get overallCompletionPercent =>
      totalQuestions == 0 ? 0.0 : (totalAttempted / totalQuestions) * 100;
}
