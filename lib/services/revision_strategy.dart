import 'dart:math';

import '../models/daily_revision_queue.dart';
import '../models/pyq_question_model.dart';
import '../models/revision_schedule.dart';

/// Strategy contract for spaced repetition revision engines to support future replacement.
abstract class RevisionStrategy {
  /// Compute updated [RevisionSchedule] given the 6 input attributes:
  /// 1. [difficulty] (Easy, Medium, Hard)
  /// 2. [lastAttempt] (DateTime of last attempt)
  /// 3. [isCorrect] (Boolean outcome of last attempt)
  /// 4. [timeTakenSeconds] (Time taken in seconds)
  /// 5. [isBookmarked] (Bookmark flag)
  /// 6. [confidenceRating] (1: Again, 2: Hard, 3: Good, 4: Easy)
  RevisionSchedule computeNextSchedule({
    required String questionId,
    required RevisionSchedule? existingSchedule,
    required bool isCorrect,
    required int confidenceRating,
    required String difficulty,
    required bool isBookmarked,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  });

  /// Calculate priority score (0.0 to 100.0) from all 6 inputs
  double calculatePriorityScore({
    required DateTime nextReviewDue,
    required int mistakeCount,
    required bool isBookmarked,
    required String difficulty,
    required int confidenceRating,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  });

  /// Categorize priority tier ('Critical', 'High', 'Medium', 'Low')
  String getPriorityTier(double priorityScore);

  /// Build [DailyRevisionQueue] ranked by priority score
  DailyRevisionQueue buildDailyQueue({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  });

  /// Build Revision Calendar mapping ISO date strings (YYYY-MM-DD) to due items
  Map<String, List<RevisionQueueItem>> buildRevisionCalendar({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  });

  /// Build Smart Recommendations list from due items and question patterns
  List<String> buildSmartRecommendations({
    required List<RevisionQueueItem> items,
  });
}

/// Default implementation of [RevisionStrategy] using adaptive SuperMemo 2 + Leitner intervals
/// and multi-attribute priority scoring.
class AdaptiveRevisionStrategy implements RevisionStrategy {
  const AdaptiveRevisionStrategy();

  @override
  RevisionSchedule computeNextSchedule({
    required String questionId,
    required RevisionSchedule? existingSchedule,
    required bool isCorrect,
    required int confidenceRating,
    required String difficulty,
    required bool isBookmarked,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  }) {
    final now = DateTime.now();
    final reviewTime = lastAttempt ?? now;

    int mistakeCount = existingSchedule?.mistakeCount ?? 0;
    double easeFactor = existingSchedule?.easeFactor ?? 2.5;
    int currentLevel = existingSchedule?.repetitionLevel ?? 1;

    if (!isCorrect) {
      mistakeCount += 1;
      currentLevel = 1;
      easeFactor = max(1.3, easeFactor - 0.2);
    } else {
      currentLevel = min(5, currentLevel + 1);
    }

    // Adjust ease factor based on confidence rating
    switch (confidenceRating) {
      case 1: // Again
        easeFactor = max(1.3, easeFactor - 0.2);
        break;
      case 2: // Hard
        easeFactor = max(1.3, easeFactor - 0.15);
        break;
      case 3: // Good
        break;
      case 4: // Easy
        easeFactor = min(3.0, easeFactor + 0.15);
        break;
    }

    // Difficulty multiplier
    double diffMultiplier = 1.0;
    final diffLower = difficulty.toLowerCase();
    if (diffLower == 'hard') {
      diffMultiplier = 0.8;
    } else if (diffLower == 'easy') {
      diffMultiplier = 1.25;
    }

    // Calculate interval days
    int intervalDays = 1;
    if (!isCorrect || confidenceRating == 1) {
      intervalDays = 1;
    } else {
      final baseInterval = _getLeitnerInterval(currentLevel);
      intervalDays = max(
        1,
        (baseInterval * (easeFactor / 2.5) * diffMultiplier).round(),
      );
      if (confidenceRating == 4) {
        intervalDays = (intervalDays * 1.3).round();
      }
    }

    final nextDue = reviewTime.add(Duration(days: intervalDays));

    final score = calculatePriorityScore(
      nextReviewDue: nextDue,
      mistakeCount: mistakeCount,
      isBookmarked: isBookmarked,
      difficulty: difficulty,
      confidenceRating: confidenceRating,
      lastAttempt: reviewTime,
      timeTakenSeconds: timeTakenSeconds,
    );

    final tier = getPriorityTier(score);

    return RevisionSchedule(
      scheduleId: questionId,
      questionId: questionId,
      lastReviewed: reviewTime,
      nextReviewDue: nextDue,
      repetitionLevel: currentLevel,
      easeFactor: easeFactor,
      mistakeCount: mistakeCount,
      confidenceRating: confidenceRating,
      priorityScore: score,
      priorityTier: tier,
      aiRecommendationReason: _generateReason(
        mistakeCount: mistakeCount,
        isBookmarked: isBookmarked,
        difficulty: difficulty,
        confidenceRating: confidenceRating,
        timeTakenSeconds: timeTakenSeconds,
      ),
    );
  }

  @override
  double calculatePriorityScore({
    required DateTime nextReviewDue,
    required int mistakeCount,
    required bool isBookmarked,
    required String difficulty,
    required int confidenceRating,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  }) {
    final now = DateTime.now();

    // 1. Time overdue factor
    final daysOverdue = max(0, now.difference(nextReviewDue).inDays);
    final overdueScore = min(35.0, daysOverdue * 5.0);

    // 2. Mistakes factor
    final mistakeScore = min(30.0, mistakeCount * 10.0);

    // 3. Bookmarks factor
    final bookmarkScore = isBookmarked ? 15.0 : 0.0;

    // 4. Difficulty factor
    double diffScore = 10.0;
    final diffLower = difficulty.toLowerCase();
    if (diffLower == 'hard') {
      diffScore = 15.0;
    } else if (diffLower == 'easy') {
      diffScore = 5.0;
    }

    // 5. Confidence factor
    final confidenceScore = (5 - min(4, max(1, confidenceRating))) * 5.0;

    // 6. Time taken hesitation factor (>90s for easy, >120s for medium/hard adds +5.0)
    double timeHesitationScore = 0.0;
    if (timeTakenSeconds > 0) {
      if (diffLower == 'easy' && timeTakenSeconds > 90) {
        timeHesitationScore = 5.0;
      } else if (timeTakenSeconds > 120) {
        timeHesitationScore = 5.0;
      }
    }

    final totalScore = overdueScore +
        mistakeScore +
        bookmarkScore +
        diffScore +
        confidenceScore +
        timeHesitationScore;
    return min(100.0, max(0.0, totalScore));
  }

  @override
  String getPriorityTier(double priorityScore) {
    if (priorityScore >= 50.0) return 'Critical';
    if (priorityScore >= 35.0) return 'High';
    if (priorityScore >= 20.0) return 'Medium';
    return 'Low';
  }

  @override
  DailyRevisionQueue buildDailyQueue({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  }) {
    final now = DateTime.now();
    final List<RevisionQueueItem> queueItems = [];

    int criticalCount = 0;
    int highCount = 0;
    int mediumCount = 0;
    int lowCount = 0;

    for (final q in questions) {
      final sched = scheduleMap[q.id];
      final isDue = sched == null ||
          sched.nextReviewDue.isBefore(now) ||
          sched.nextReviewDue.isAtSameMomentAs(now) ||
          q.isBookmarked ||
          (q.isAttempted && !q.isLastAttemptCorrect);

      if (isDue) {
        final nextDue = sched?.nextReviewDue ?? now;
        final mistakes =
            sched?.mistakeCount ?? (q.isLastAttemptCorrect ? 0 : 1);
        final conf = sched?.confidenceRating ?? 3;

        final score = calculatePriorityScore(
          nextReviewDue: nextDue,
          mistakeCount: mistakes,
          isBookmarked: q.isBookmarked,
          difficulty: q.difficulty,
          confidenceRating: conf,
          lastAttempt: q.lastAttempted,
        );

        final tier = getPriorityTier(score);

        if (tier == 'Critical') criticalCount++;
        if (tier == 'High') highCount++;
        if (tier == 'Medium') mediumCount++;
        if (tier == 'Low') lowCount++;

        final effectiveSched = sched ??
            RevisionSchedule(
              scheduleId: q.id,
              questionId: q.id,
              lastReviewed: q.lastAttempted ?? now,
              nextReviewDue: nextDue,
              mistakeCount: mistakes,
              confidenceRating: conf,
              priorityScore: score,
              priorityTier: tier,
            );

        queueItems.add(RevisionQueueItem(
          question: q,
          schedule: effectiveSched,
          priorityScore: score,
          priorityTier: tier,
          reason: _generateReason(
            mistakeCount: mistakes,
            isBookmarked: q.isBookmarked,
            difficulty: q.difficulty,
            confidenceRating: conf,
          ),
        ));
      }
    }

    // Sort Queue by Priority Score Descending
    queueItems.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    // Generate Smart Reminder
    final smartReminder = _generateSmartReminder(
      totalDue: queueItems.length,
      criticalCount: criticalCount,
      highCount: highCount,
    );

    // Generate Recommendations
    final recommendations = buildSmartRecommendations(items: queueItems);
    final aiSummary = recommendations.isNotEmpty
        ? recommendations.first
        : "AI Recommendation: Excellent retention across all topics!";

    return DailyRevisionQueue(
      date: now,
      totalDueCount: queueItems.length,
      criticalCount: criticalCount,
      highCount: highCount,
      mediumCount: mediumCount,
      lowCount: lowCount,
      items: queueItems,
      smartReminderMessage: smartReminder,
      aiRecommendationSummary: aiSummary,
    );
  }

  @override
  Map<String, List<RevisionQueueItem>> buildRevisionCalendar({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  }) {
    final Map<String, List<RevisionQueueItem>> calendar = {};
    final now = DateTime.now();

    for (final q in questions) {
      final sched = scheduleMap[q.id];
      final dueTime = sched?.nextReviewDue ?? now;
      final dateKey =
          "${dueTime.year}-${_twoDigits(dueTime.month)}-${_twoDigits(dueTime.day)}";

      final score = calculatePriorityScore(
        nextReviewDue: dueTime,
        mistakeCount: sched?.mistakeCount ?? 0,
        isBookmarked: q.isBookmarked,
        difficulty: q.difficulty,
        confidenceRating: sched?.confidenceRating ?? 3,
        lastAttempt: q.lastAttempted,
      );
      final tier = getPriorityTier(score);

      final item = RevisionQueueItem(
        question: q,
        schedule: sched ??
            RevisionSchedule(
              scheduleId: q.id,
              questionId: q.id,
              lastReviewed: q.lastAttempted ?? now,
              nextReviewDue: dueTime,
              priorityScore: score,
              priorityTier: tier,
            ),
        priorityScore: score,
        priorityTier: tier,
        reason: _generateReason(
          mistakeCount: sched?.mistakeCount ?? 0,
          isBookmarked: q.isBookmarked,
          difficulty: q.difficulty,
          confidenceRating: sched?.confidenceRating ?? 3,
        ),
      );

      calendar.putIfAbsent(dateKey, () => []).add(item);
    }

    // Sort items inside each calendar date by priority score descending
    calendar.forEach((key, items) {
      items.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    });

    return calendar;
  }

  @override
  List<String> buildSmartRecommendations({
    required List<RevisionQueueItem> items,
  }) {
    final List<String> recommendations = [];
    if (items.isEmpty) {
      recommendations.add(
          "AI Recommendation: All revision queues are clear! Perform a fresh mock test.");
      return recommendations;
    }

    // 1. Critical Count Warning
    final criticals = items.where((i) => i.priorityTier == 'Critical').length;
    if (criticals > 0) {
      recommendations.add(
          "AI Priority: $criticals critical questions need immediate review to prevent memory decay.");
    }

    // 2. Subject Breakdown in Queue
    final Map<String, int> subjectCounts = {};
    for (final item in items) {
      final sub =
          item.question.subject.isNotEmpty ? item.question.subject : 'General';
      subjectCounts[sub] = (subjectCounts[sub] ?? 0) + 1;
    }

    if (subjectCounts.isNotEmpty) {
      final topSubject = subjectCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      recommendations.add(
          "Focus Subject: $topSubject has ${subjectCounts[topSubject]} due items in your queue.");
    }

    // 3. Bookmarks focus
    final bookmarksInQueue = items.where((i) => i.question.isBookmarked).length;
    if (bookmarksInQueue > 0) {
      recommendations.add(
          "Bookmarked Review: You have $bookmarksInQueue bookmarked questions scheduled for high-yield practice.");
    }

    return recommendations;
  }

  static int _getLeitnerInterval(int level) {
    switch (level) {
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 7;
      case 4:
        return 14;
      case 5:
        return 30;
      default:
        return 1;
    }
  }

  static String _generateSmartReminder({
    required int totalDue,
    required int criticalCount,
    required int highCount,
  }) {
    if (totalDue == 0) {
      return "🎉 Great job! Your revision queue is clear for today.";
    }
    if (criticalCount > 0) {
      return "🔥 $criticalCount Critical questions need urgent review today to maintain high recall!";
    }
    if (highCount > 0) {
      return "⚡ You have $totalDue questions due ($highCount High priority). Spend 15 minutes to revise!";
    }
    return "📚 $totalDue questions in your daily queue ready for review.";
  }

  static String _generateReason({
    required int mistakeCount,
    required bool isBookmarked,
    required String difficulty,
    required int confidenceRating,
    int timeTakenSeconds = 0,
  }) {
    final List<String> reasons = [];
    if (mistakeCount > 0) reasons.add("$mistakeCount past mistake(s)");
    if (isBookmarked) reasons.add("Bookmarked question");
    if (difficulty.toLowerCase() == 'hard') {
      reasons.add("Hard difficulty rating");
    }
    if (confidenceRating <= 2) reasons.add("Low confidence rating");
    if (timeTakenSeconds > 90) reasons.add("High response time");
    if (reasons.isEmpty) reasons.add("Scheduled spaced review");
    return reasons.join(' • ');
  }

  static String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";
}
