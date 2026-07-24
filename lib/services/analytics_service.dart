import 'dart:math';
import '../models/analytics_engine_models.dart';
import '../models/pyq_question_model.dart';

/// Comprehensive Analytics Service for QuizForge AI.
class AnalyticsService {
  /// Compute full [LearningInsightsModel] across all 16 tracked dimensions.
  LearningInsightsModel computeLearningInsights(
      List<PyqQuestionModel> questions) {
    int totalQuestions = questions.length;
    int totalAttempted = 0;
    int totalCorrect = 0;
    int bookmarkCount = 0;
    int incorrectCount = 0;
    int totalTimeSpentSeconds = 0;

    final Map<String, _AccTracker> subjectAcc = {};
    final Map<String, _AccTracker> topicAcc = {};
    final Map<int, _AccTracker> yearAcc = {};
    final Map<String, _AccTracker> difficultyAcc = {};
    final Map<String, int> attemptFrequency = {};

    final Set<String> activeDates = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int dailySolved = 0;
    int weeklySolved = 0;
    int monthlySolved = 0;

    for (final q in questions) {
      if (q.isBookmarked) {
        bookmarkCount++;
      }

      attemptFrequency[q.id] = q.timesAttempted;

      if (q.isAttempted && !q.isLastAttemptCorrect) {
        incorrectCount++;
      }

      if (q.isAttempted) {
        totalAttempted++;
        totalCorrect += q.timesCorrect;

        // Approx 45s per attempt or calculate from timestamp
        final timeForQ = q.timesAttempted * 45;
        totalTimeSpentSeconds += timeForQ;

        if (q.lastAttempted != null) {
          final dt = q.lastAttempted!;
          final dateKey =
              "${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}";
          activeDates.add(dateKey);

          final attemptedDate = DateTime(dt.year, dt.month, dt.day);
          final diffDays = today.difference(attemptedDate).inDays;

          if (diffDays == 0) {
            dailySolved++;
          }
          if (diffDays >= 0 && diffDays < 7) {
            weeklySolved++;
          }
          if (diffDays >= 0 && diffDays < 30) {
            monthlySolved++;
          }
        }
      }

      // 1. Subject Tracker
      final sKey = q.subject.isNotEmpty ? q.subject : 'General';
      final sAcc = subjectAcc.putIfAbsent(sKey, () => _AccTracker(sKey));
      sAcc.total++;
      if (q.isAttempted) {
        sAcc.attempted += q.timesAttempted;
        sAcc.correct += q.timesCorrect;
        sAcc.timeSpent += q.timesAttempted * 45;
      }

      // 2. Topic Tracker
      final tKey = q.topic.isNotEmpty ? q.topic : 'General';
      final tAcc = topicAcc.putIfAbsent(tKey, () => _AccTracker(tKey));
      tAcc.total++;
      if (q.isAttempted) {
        tAcc.attempted += q.timesAttempted;
        tAcc.correct += q.timesCorrect;
        tAcc.timeSpent += q.timesAttempted * 45;
      }

      // 3. Year Tracker
      final yKey = q.year;
      final yAcc =
          yearAcc.putIfAbsent(yKey, () => _AccTracker(yKey.toString()));
      yAcc.total++;
      if (q.isAttempted) {
        yAcc.attempted += q.timesAttempted;
        yAcc.correct += q.timesCorrect;
        yAcc.timeSpent += q.timesAttempted * 45;
      }

      // 4. Difficulty Tracker
      final dKey = q.difficulty.isNotEmpty ? q.difficulty : 'Medium';
      final dAcc = difficultyAcc.putIfAbsent(dKey, () => _AccTracker(dKey));
      dAcc.total++;
      if (q.isAttempted) {
        dAcc.attempted += q.timesAttempted;
        dAcc.correct += q.timesCorrect;
        dAcc.timeSpent += q.timesAttempted * 45;
      }
    }

    // Convert Trackers to EntityAccuracy maps
    final Map<String, EntityAccuracy> subjectAccuracyMap = {};
    subjectAcc.forEach((k, v) {
      subjectAccuracyMap[k] = EntityAccuracy(
        key: k,
        totalQuestions: v.total,
        attemptedQuestions: v.attempted,
        correctQuestions: v.correct,
        totalTimeSpentSeconds: v.timeSpent,
      );
    });

    final Map<String, EntityAccuracy> topicAccuracyMap = {};
    topicAcc.forEach((k, v) {
      topicAccuracyMap[k] = EntityAccuracy(
        key: k,
        totalQuestions: v.total,
        attemptedQuestions: v.attempted,
        correctQuestions: v.correct,
        totalTimeSpentSeconds: v.timeSpent,
      );
    });

    final Map<int, EntityAccuracy> yearAccuracyMap = {};
    yearAcc.forEach((k, v) {
      yearAccuracyMap[k] = EntityAccuracy(
        key: k.toString(),
        totalQuestions: v.total,
        attemptedQuestions: v.attempted,
        correctQuestions: v.correct,
        totalTimeSpentSeconds: v.timeSpent,
      );
    });

    final Map<String, EntityAccuracy> difficultyAccuracyMap = {};
    difficultyAcc.forEach((k, v) {
      difficultyAccuracyMap[k] = EntityAccuracy(
        key: k,
        totalQuestions: v.total,
        attemptedQuestions: v.attempted,
        correctQuestions: v.correct,
        totalTimeSpentSeconds: v.timeSpent,
      );
    });

    // Overall Accuracy
    final double overallAccuracy =
        totalAttempted == 0 ? 0.0 : (totalCorrect / totalAttempted) * 100;

    // Average Time Per Question
    final double avgTimePerQuestion =
        totalAttempted == 0 ? 0.0 : totalTimeSpentSeconds / totalAttempted;

    // Streaks
    final streakData = _computeStreaks(activeDates);

    // Weak Area Detection with Confidence Levels
    final weakInsights = _detectWeakAreaInsights(
      subjectAccuracyMap: subjectAccuracyMap,
      topicAccuracyMap: topicAccuracyMap,
      yearAccuracyMap: yearAccuracyMap,
      difficultyAccuracyMap: difficultyAccuracyMap,
    );

    final List<String> weakSubjects = subjectAccuracyMap.values
        .where((e) => e.attemptedQuestions > 0 && e.accuracyPercent < 50.0)
        .map((e) => e.key)
        .toList();

    final List<String> strongSubjects = subjectAccuracyMap.values
        .where((e) => e.attemptedQuestions > 0 && e.accuracyPercent >= 70.0)
        .map((e) => e.key)
        .toList();

    // Revision Completion %
    final double revisionCompletion =
        totalQuestions == 0 ? 0.0 : (totalAttempted / totalQuestions) * 100;

    return LearningInsightsModel(
      overallAccuracy: overallAccuracy,
      subjectAccuracy: subjectAccuracyMap,
      topicAccuracy: topicAccuracyMap,
      yearAccuracy: yearAccuracyMap,
      difficultyAccuracy: difficultyAccuracyMap,
      averageTimePerQuestionSeconds: avgTimePerQuestion,
      averageQuizScore: overallAccuracy,
      dailyQuestionsSolved: dailySolved,
      weeklyQuestionsSolved: weeklySolved,
      monthlyQuestionsSolved: monthlySolved,
      currentStreak: streakData.currentStreak,
      longestStreak: streakData.maxStreak,
      revisionCompletionPercent: revisionCompletion,
      bookmarkCount: bookmarkCount,
      incorrectQuestionCount: incorrectCount,
      questionAttemptFrequency: attemptFrequency,
      weakAreaInsights: weakInsights,
      strongSubjects: strongSubjects,
      weakSubjects: weakSubjects,
    );
  }

  /// Weak area detection across Subjects, Topics, Difficulties, and Years with Confidence Ratings.
  List<WeakAreaInsight> _detectWeakAreaInsights({
    required Map<String, EntityAccuracy> subjectAccuracyMap,
    required Map<String, EntityAccuracy> topicAccuracyMap,
    required Map<int, EntityAccuracy> yearAccuracyMap,
    required Map<String, EntityAccuracy> difficultyAccuracyMap,
  }) {
    final List<WeakAreaInsight> insights = [];

    // 1. Weak Subjects
    for (final entry in subjectAccuracyMap.entries) {
      if (entry.value.attemptedQuestions > 0 &&
          entry.value.accuracyPercent < 55.0) {
        final confidence =
            ConfidenceLevel.fromAttemptCount(entry.value.attemptedQuestions);
        insights.add(WeakAreaInsight(
          dimension: 'subject',
          name: entry.key,
          accuracyPercent: entry.value.accuracyPercent,
          attemptedCount: entry.value.attemptedQuestions,
          correctCount: entry.value.correctQuestions,
          confidenceLevel: confidence,
          recommendation:
              'Revise core concepts of ${entry.key} and solve past year questions.',
        ));
      }
    }

    // 2. Weak Topics
    for (final entry in topicAccuracyMap.entries) {
      if (entry.value.attemptedQuestions > 0 &&
          entry.value.accuracyPercent < 50.0) {
        final confidence =
            ConfidenceLevel.fromAttemptCount(entry.value.attemptedQuestions);
        insights.add(WeakAreaInsight(
          dimension: 'topic',
          name: entry.key,
          accuracyPercent: entry.value.accuracyPercent,
          attemptedCount: entry.value.attemptedQuestions,
          correctCount: entry.value.correctQuestions,
          confidenceLevel: confidence,
          recommendation:
              'Focus on topic "${entry.key}" in your next revision session.',
        ));
      }
    }

    // 3. Weak Difficulties
    for (final entry in difficultyAccuracyMap.entries) {
      if (entry.value.attemptedQuestions > 0 &&
          entry.value.accuracyPercent < 50.0) {
        final confidence =
            ConfidenceLevel.fromAttemptCount(entry.value.attemptedQuestions);
        insights.add(WeakAreaInsight(
          dimension: 'difficulty',
          name: entry.key,
          accuracyPercent: entry.value.accuracyPercent,
          attemptedCount: entry.value.attemptedQuestions,
          correctCount: entry.value.correctQuestions,
          confidenceLevel: confidence,
          recommendation:
              'Practice more ${entry.key} difficulty level questions with detailed explanations.',
        ));
      }
    }

    // 4. Weak Years
    for (final entry in yearAccuracyMap.entries) {
      if (entry.value.attemptedQuestions > 0 &&
          entry.value.accuracyPercent < 50.0) {
        final confidence =
            ConfidenceLevel.fromAttemptCount(entry.value.attemptedQuestions);
        insights.add(WeakAreaInsight(
          dimension: 'year',
          name: entry.key.toString(),
          accuracyPercent: entry.value.accuracyPercent,
          attemptedCount: entry.value.attemptedQuestions,
          correctCount: entry.value.correctQuestions,
          confidenceLevel: confidence,
          recommendation: 'Re-attempt UPSC paper for year ${entry.key}.',
        ));
      }
    }

    insights.sort((a, b) => a.accuracyPercent.compareTo(b.accuracyPercent));
    return insights;
  }

  /// Create a historical trend snapshot from current insights.
  AnalyticsSnapshot createSnapshot(LearningInsightsModel insights) {
    return AnalyticsSnapshot(
      snapshotId: 'snap_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toUtc(),
      overallAccuracy: insights.overallAccuracy,
      questionsSolved: insights.dailyQuestionsSolved,
      currentStreak: insights.currentStreak,
      weakSubjects: insights.weakSubjects,
      strongSubjects: insights.strongSubjects,
    );
  }

  _StreakData _computeStreaks(Set<String> activeDates) {
    if (activeDates.isEmpty) return _StreakData(currentStreak: 0, maxStreak: 0);

    final sortedDates = activeDates.map((d) => DateTime.parse(d)).toList()
      ..sort();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = 0;
    int maxStreak = 0;
    DateTime? prevDate;

    for (final dt in sortedDates) {
      final curDay = DateTime(dt.year, dt.month, dt.day);
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final diff = curDay.difference(prevDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else if (diff > 1) {
          currentStreak = 1;
        }
      }
      maxStreak = max(maxStreak, currentStreak);
      prevDate = curDay;
    }

    if (prevDate != null) {
      final diffFromToday = today.difference(prevDate).inDays;
      if (diffFromToday > 1) {
        currentStreak = 0;
      }
    }

    return _StreakData(currentStreak: currentStreak, maxStreak: maxStreak);
  }

  static String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";
}

class _AccTracker {
  final String name;
  int total = 0;
  int attempted = 0;
  int correct = 0;
  int timeSpent = 0;
  _AccTracker(this.name);
}

class _StreakData {
  final int currentStreak;
  final int maxStreak;
  _StreakData({required this.currentStreak, required this.maxStreak});
}
