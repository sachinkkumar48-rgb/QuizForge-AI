import '../models/daily_revision_queue.dart';
import '../models/pyq_analytics_model.dart';
import '../models/pyq_question_model.dart';

abstract class PyqRepository {
  /// Initialize repository and seed default asset dataset if database is empty.
  Future<void> init();

  /// Retrieve all PYQ questions.
  Future<List<PyqQuestionModel>> getAllQuestions();

  /// Retrieve questions by year (e.g. 2024).
  Future<List<PyqQuestionModel>> getQuestionsByYear(int year);

  /// Retrieve questions by subject (e.g. "Polity").
  Future<List<PyqQuestionModel>> getQuestionsBySubject(String subject);

  /// Retrieve questions by topic (e.g. "Preamble").
  Future<List<PyqQuestionModel>> getQuestionsByTopic(String topic);

  /// Retrieve all bookmarked questions.
  Future<List<PyqQuestionModel>> getBookmarkedQuestions();

  /// Retrieve all incorrectly answered questions (Mistake Bank).
  Future<List<PyqQuestionModel>> getIncorrectQuestions();

  /// Retrieve questions mapped to a specific curriculum [objectiveId].
  Future<List<PyqQuestionModel>> getQuestionsForObjective(String objectiveId);

  /// Search & filter questions by multi-parameters.
  Future<List<PyqQuestionModel>> searchQuestions({
    String? query,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    bool? onlyBookmarked,
    bool? onlyIncorrect,
    bool? unattempted,
  });

  /// Toggle bookmark state for a question.
  Future<void> toggleBookmark(String questionId);

  /// Record a user attempt for a question.
  Future<void> recordAttempt({
    required String questionId,
    required String selectedAnswer,
    String? learnerId,
    String? objectiveId,
  });

  /// Generate a custom Mock Test subset of PYQs.
  Future<List<PyqQuestionModel>> generateMockTest({
    required int count,
    String? subject,
    String? topic,
    List<int>? years,
  });

  /// Generate a Smart Revision session based on weak topics, mistakes, bookmarks, and stale questions.
  Future<List<PyqQuestionModel>> generateSmartRevision({
    int count = 20,
    bool includeIncorrect = true,
    bool includeBookmarked = true,
    bool includeWeak = true,
  });

  /// Build prioritized Daily Revision Queue based on 5 spaced-repetition factors.
  Future<DailyRevisionQueue> getDailyRevisionQueue();

  /// Record spaced repetition review with confidence feedback rating (1-4).
  Future<void> recordSpacedRevisionResult({
    required String questionId,
    required bool isCorrect,
    required int confidenceRating,
  });

  /// Import external JSON dataset.
  Future<int> importDataset(String jsonString);

  /// Compute overall analytics.
  Future<PyqAnalyticsModel> getAnalytics();

  /// Clear all stored data (for testing or reset).
  Future<void> clear();
}
