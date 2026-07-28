import '../models/learning_content_models.dart';

/// Clean Architecture abstract repository interface for managing LearningContent domain entities.
abstract class LearningContentRepository {
  /// Retrieves a content item by its unique ID.
  Future<LearningContent?> getContentById(String id);

  /// Retrieves all content items associated with a chapter ID.
  Future<List<LearningContent>> getChapterContents(String chapterId);

  /// Updates progress for a specific content item and user.
  Future<ContentProgress> updateProgress({
    required String userId,
    required String contentId,
    required int lastPositionSeconds,
    required double completionPercentage,
    required int timeSpentSeconds,
  });

  /// Marks a content item as officially completed.
  Future<ContentCompletion> markCompleted({
    required String userId,
    required String contentId,
    double? score,
    String? feedback,
  });

  /// Retrieves learning objectives for a content item.
  Future<List<ContentObjective>> getObjectives(String contentId);

  /// Retrieves prerequisites required for a content item.
  Future<List<ContentPrerequisite>> getPrerequisites(String contentId);

  /// Retrieves expected outcomes for a content item.
  Future<List<ContentOutcome>> getOutcomes(String contentId);

  /// Retrieves content from local offline cache.
  Future<LearningContent?> getCachedContent(String contentId);

  /// Triggers background sync for offline content & activity records.
  Future<void> syncContent({required String userId});
}
