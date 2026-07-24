import '../models/daily_revision_queue.dart';
import '../models/pyq_question_model.dart';
import '../models/revision_schedule.dart';
import 'revision_strategy.dart';

class SpacedRepetitionScheduler {
  static RevisionStrategy _strategy = const AdaptiveRevisionStrategy();

  SpacedRepetitionScheduler._();

  /// Set pluggable revision strategy
  static void setStrategy(RevisionStrategy strategy) {
    _strategy = strategy;
  }

  /// Get current active strategy
  static RevisionStrategy get currentStrategy => _strategy;

  /// Calculate updated RevisionSchedule given user confidence feedback and question attributes
  static RevisionSchedule computeNextSchedule({
    required String questionId,
    required RevisionSchedule? existingSchedule,
    required bool isCorrect,
    required int confidenceRating, // 1: Again, 2: Hard, 3: Good, 4: Easy
    required String difficulty,
    required bool isBookmarked,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  }) {
    return _strategy.computeNextSchedule(
      questionId: questionId,
      existingSchedule: existingSchedule,
      isCorrect: isCorrect,
      confidenceRating: confidenceRating,
      difficulty: difficulty,
      isBookmarked: isBookmarked,
      lastAttempt: lastAttempt,
      timeTakenSeconds: timeTakenSeconds,
    );
  }

  /// Calculate priority score (0.0 to 100.0) from all 6 inputs
  static double calculatePriorityScore({
    required DateTime nextReviewDue,
    required int mistakeCount,
    required bool isBookmarked,
    required String difficulty,
    required int confidenceRating,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  }) {
    return _strategy.calculatePriorityScore(
      nextReviewDue: nextReviewDue,
      mistakeCount: mistakeCount,
      isBookmarked: isBookmarked,
      difficulty: difficulty,
      confidenceRating: confidenceRating,
      lastAttempt: lastAttempt,
      timeTakenSeconds: timeTakenSeconds,
    );
  }

  /// Categorize priority tier
  static String getPriorityTier(double priorityScore) {
    return _strategy.getPriorityTier(priorityScore);
  }

  /// Build Daily Revision Queue ranked by priority
  static DailyRevisionQueue buildDailyQueue({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  }) {
    return _strategy.buildDailyQueue(
      questions: questions,
      scheduleMap: scheduleMap,
    );
  }

  /// Build Revision Calendar mapping ISO date strings (YYYY-MM-DD) to due items
  static Map<String, List<RevisionQueueItem>> buildRevisionCalendar({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  }) {
    return _strategy.buildRevisionCalendar(
      questions: questions,
      scheduleMap: scheduleMap,
    );
  }

  /// Build Smart Recommendations list
  static List<String> buildSmartRecommendations({
    required List<RevisionQueueItem> items,
  }) {
    return _strategy.buildSmartRecommendations(items: items);
  }

  /// Generate smart reminder notifications
  static String generateSmartReminder({
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

  /// Future AI Recommendation Hook
  static String generateAiRecommendation(List<RevisionQueueItem> items) {
    final recs = _strategy.buildSmartRecommendations(items: items);
    return recs.isNotEmpty
        ? recs.first
        : "AI Recommendation: Excellent retention across all topics!";
  }
}
