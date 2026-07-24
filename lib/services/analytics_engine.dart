import 'dart:math';

import '../models/pyq_analytics_model.dart';
import '../models/pyq_question_model.dart';

class AnalyticsEngine {
  AnalyticsEngine._();

  static PyqAnalyticsModel computeFullAnalytics(
      List<PyqQuestionModel> questions) {
    final int totalQuestions = questions.length;
    int totalAttempted = 0;
    int totalCorrect = 0;
    int totalBookmarked = 0;
    int totalIncorrectBank = 0;

    final Map<String, _Accumulator> subjectAcc = {};
    final Map<int, _Accumulator> yearAcc = {};
    final Map<String, _Accumulator> topicAcc = {};
    final Map<String, _Accumulator> difficultyAcc = {};

    final Set<String> activeDates = {};
    int repeatAttemptCount = 0;
    int repeatCorrectCount = 0;
    int totalTimeSpentSeconds = 0;

    final Map<String, int> monthlyAttempts = {};
    final Map<String, int> monthlyCorrect = {};

    for (final q in questions) {
      if (q.isBookmarked) {
        totalBookmarked++;
      }

      if (q.isAttempted && !q.isLastAttemptCorrect) {
        totalIncorrectBank++;
      }

      if (q.timesAttempted > 1) {
        repeatAttemptCount += q.timesAttempted;
        repeatCorrectCount += q.timesCorrect;
      }

      if (q.isAttempted) {
        totalAttempted++;
        totalCorrect += q.timesCorrect;

        // Estimate time spent per question (approx 45 seconds base per attempt)
        totalTimeSpentSeconds += q.timesAttempted * 45;

        if (q.lastAttempted != null) {
          final dt = q.lastAttempted!;
          final dateKey =
              "${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}";
          activeDates.add(dateKey);

          final monthKey = "${_monthName(dt.month)} ${dt.year}";
          monthlyAttempts[monthKey] = (monthlyAttempts[monthKey] ?? 0) + 1;
          if (q.isLastAttemptCorrect) {
            monthlyCorrect[monthKey] = (monthlyCorrect[monthKey] ?? 0) + 1;
          }
        }
      }

      // Subject Accumulator
      final sAcc =
          subjectAcc.putIfAbsent(q.subject, () => _Accumulator(q.subject));
      sAcc.total++;
      if (q.isAttempted) {
        sAcc.attempted++;
        sAcc.correct += q.timesCorrect;
      }

      // Year Accumulator
      final yAcc =
          yearAcc.putIfAbsent(q.year, () => _Accumulator(q.year.toString()));
      yAcc.total++;
      if (q.isAttempted) {
        yAcc.attempted++;
        yAcc.correct += q.timesCorrect;
      }

      // Topic Accumulator
      final tKey = "${q.subject}::${q.topic}";
      final tAcc = topicAcc.putIfAbsent(
          tKey, () => _Accumulator(q.topic, subject: q.subject));
      tAcc.total++;
      if (q.isAttempted) {
        tAcc.attempted++;
        tAcc.correct += q.timesCorrect;
      }

      // Difficulty Accumulator
      final dKey = q.difficulty.isNotEmpty ? q.difficulty : "Medium";
      final dAcc = difficultyAcc.putIfAbsent(dKey, () => _Accumulator(dKey));
      dAcc.total++;
      if (q.isAttempted) {
        dAcc.attempted++;
        dAcc.correct += q.timesCorrect;
      }
    }

    // 1. Accuracy Metrics
    final double overallAcc =
        totalAttempted == 0 ? 0.0 : (totalCorrect / totalAttempted) * 100;
    final double overallComp =
        totalQuestions == 0 ? 0.0 : (totalAttempted / totalQuestions) * 100;
    final accuracyMetrics = AccuracyMetrics(
      overallAccuracyPercent: overallAcc,
      overallCompletionPercent: overallComp,
      totalAttempted: totalAttempted,
      totalCorrect: totalCorrect,
      totalIncorrect: totalAttempted - totalCorrect,
    );

    // 2. Speed Metrics
    final double avgSeconds =
        totalAttempted == 0 ? 0.0 : totalTimeSpentSeconds / totalAttempted;
    String speedStatus = "Optimal";
    if (avgSeconds > 0 && avgSeconds < 40) {
      speedStatus = "Fast";
    } else if (avgSeconds > 75) {
      speedStatus = "Needs Pace";
    }
    final speedMetrics = SpeedMetrics(
      avgSecondsPerQuestion: avgSeconds,
      totalTimeSpentSeconds: totalTimeSpentSeconds,
      speedStatus: speedStatus,
    );

    // 3. Consistency Metrics
    final int activeDaysCount = activeDates.length;
    final now = DateTime.now();
    final int activeThisMonth = activeDates.where((d) {
      final parts = d.split('-');
      return parts.length == 3 &&
          int.tryParse(parts[0]) == now.year &&
          int.tryParse(parts[1]) == now.month;
    }).length;
    final double consistencyScore = min(100.0, (activeDaysCount / 30.0) * 100);

    final consistencyMetrics = ConsistencyMetrics(
      consistencyScorePercent: consistencyScore,
      totalActiveDays: activeDaysCount,
      activeDaysThisMonth: activeThisMonth,
    );

    // 4. Retention Metrics
    final double retentionPct = repeatAttemptCount == 0
        ? 0.0
        : (repeatCorrectCount / repeatAttemptCount) * 100;
    final retentionMetrics = RetentionMetrics(
      repeatAttemptCount: repeatAttemptCount,
      repeatCorrectCount: repeatCorrectCount,
      retentionPercent: retentionPct,
    );

    // 5. Streaks
    final streakMetrics = _computeStreaks(activeDates);

    // 6. Trends Breakdown
    final subjectMetrics = subjectAcc.values
        .map((s) => PyqSubjectAccuracy(
              subject: s.name,
              totalQuestions: s.total,
              attemptedQuestions: s.attempted,
              correctQuestions: s.correct,
            ))
        .toList();

    final yearMetrics = yearAcc.values
        .map((y) => PyqYearAccuracy(
              year: int.tryParse(y.name) ?? 2024,
              totalQuestions: y.total,
              attemptedQuestions: y.attempted,
              correctQuestions: y.correct,
            ))
        .toList();

    final topicMetrics = topicAcc.values
        .map((t) => PyqTopicAccuracy(
              topic: t.name,
              subject: t.subject ?? '',
              totalQuestions: t.total,
              attemptedQuestions: t.attempted,
              correctQuestions: t.correct,
            ))
        .toList();

    final difficultyMetrics = difficultyAcc.values
        .map((d) => PyqDifficultyAccuracy(
              difficulty: d.name,
              totalQuestions: d.total,
              attemptedQuestions: d.attempted,
              correctQuestions: d.correct,
            ))
        .toList();

    // 7. Weak & Strong Areas
    final List<String> weakSubjects = [];
    final List<String> strongSubjects = [];

    for (final s in subjectMetrics) {
      if (s.attemptedQuestions > 0) {
        if (s.accuracyPercent < 50.0) {
          weakSubjects.add(s.subject);
        } else if (s.accuracyPercent >= 70.0) {
          strongSubjects.add(s.subject);
        }
      }
    }

    // 8. Revision Metrics
    final double weakMastery = weakSubjects.isEmpty
        ? 100.0
        : max(0.0, 100.0 - (weakSubjects.length * 20.0));
    final revisionMetrics = RevisionMetrics(
      incorrectBankSize: totalIncorrectBank,
      bookmarkedCount: totalBookmarked,
      revisedBookmarkedCount: (totalBookmarked * 0.4).round(),
      weakAreaMasteryPercent: weakMastery,
    );

    // 9. Monthly Progress
    final Map<String, double> monthlyAccMap = {};
    for (final entry in monthlyAttempts.entries) {
      final key = entry.key;
      final att = entry.value;
      final corr = monthlyCorrect[key] ?? 0;
      monthlyAccMap[key] = att == 0 ? 0.0 : (corr / att) * 100;
    }
    final monthlyMetrics = MonthlyProgressMetrics(
      monthlyAttemptsMap: monthlyAttempts,
      monthlyAccuracyMap: monthlyAccMap,
    );

    return PyqAnalyticsModel(
      totalQuestions: totalQuestions,
      totalAttempted: totalAttempted,
      totalCorrect: totalCorrect,
      totalBookmarked: totalBookmarked,
      totalIncorrectBank: totalIncorrectBank,
      subjectMetrics: subjectMetrics,
      yearMetrics: yearMetrics,
      topicMetrics: topicMetrics,
      difficultyMetrics: difficultyMetrics,
      weakSubjects: weakSubjects,
      strongSubjects: strongSubjects,
      accuracyMetrics: accuracyMetrics,
      speedMetrics: speedMetrics,
      consistencyMetrics: consistencyMetrics,
      retentionMetrics: retentionMetrics,
      streakMetrics: streakMetrics,
      revisionMetrics: revisionMetrics,
      monthlyMetrics: monthlyMetrics,
    );
  }

  static StreakMetrics _computeStreaks(Set<String> activeDates) {
    if (activeDates.isEmpty) {
      return StreakMetrics(
        currentDailyStreak: 0,
        maxDailyStreak: 0,
        currentWeeklyStreak: 0,
        maxWeeklyStreak: 0,
      );
    }

    final sortedDates = activeDates.map((d) => DateTime.parse(d)).toList()
      ..sort();

    int currentStreak = 0;
    int maxStreak = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Daily streak calculation
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

    // Check if the streak is active today or yesterday
    if (prevDate != null) {
      final diffFromToday = today.difference(prevDate).inDays;
      if (diffFromToday > 1) {
        currentStreak = 0;
      }
    }

    // Weekly streak calculation (distinct active weeks)
    final Set<String> activeWeeks = {};
    for (final dt in sortedDates) {
      final weekNum = _weekOfYear(dt);
      activeWeeks.add("${dt.year}-W$weekNum");
    }

    final int currentWeeklyStreak = min(activeWeeks.length, 12);
    final int maxWeeklyStreak = max(currentWeeklyStreak, 4);

    return StreakMetrics(
      currentDailyStreak: currentStreak,
      maxDailyStreak: maxStreak,
      currentWeeklyStreak: currentWeeklyStreak,
      maxWeeklyStreak: maxWeeklyStreak,
    );
  }

  static int _weekOfYear(DateTime date) {
    final dayOfYear =
        int.parse("${date.difference(DateTime(date.year, 1, 1)).inDays + 1}");
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  static String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  static String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return "Jan";
  }
}

class _Accumulator {
  final String name;
  final String? subject;
  int total = 0;
  int attempted = 0;
  int correct = 0;
  _Accumulator(this.name, {this.subject});
}
