import '../models/revision_models.dart';

/// Abstract repository interface defining adaptive revision queue operations.
abstract class RevisionRepository {
  /// Generates or retrieves a personalized revision queue.
  Future<RevisionQueue> getPersonalizedRevisionQueue({
    String? category,
    bool? overdueOnly,
  });

  /// Processes user recall rating (0-5) for an item and updates its SM-2 schedule.
  Future<RevisionItem> recordRevisionAttempt(
    String itemId,
    int qualityRating,
  );

  /// Adds a new topic or quiz mistake to the adaptive revision queue.
  Future<RevisionItem> addTopicToRevision({
    required String topic,
    String? subtopic,
    String? questionId,
    String? questionText,
    String priority = 'High',
    String sourceTag = 'Quiz Mistake',
  });

  /// Retrieves overdue revision items requiring immediate recall.
  Future<List<RevisionItem>> getOverdueItems();

  /// Returns topic mastery percentages (topic -> mastery percentage 0.0 - 100.0).
  Future<Map<String, double>> getTopicMasteryOverview();
}
