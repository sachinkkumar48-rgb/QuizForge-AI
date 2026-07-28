import '../models/video_models.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for saving bookmarks on video timestamps.
class ToggleBookmarkUseCase {
  final VideoRepository _repository;

  const ToggleBookmarkUseCase(this._repository);

  /// Saves a timestamped bookmark for [userId] on [contentId].
  Future<VideoBookmark> execute({
    required String userId,
    required String contentId,
    required int timestampSeconds,
    required String note,
  }) {
    return _repository.saveBookmark(
      userId: userId,
      contentId: contentId,
      timestampSeconds: timestampSeconds,
      note: note,
    );
  }
}
