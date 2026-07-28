import '../models/video_models.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for fetching video subtitle tracks.
class GetSubtitlesUseCase {
  final VideoRepository _repository;

  const GetSubtitlesUseCase(this._repository);

  /// Retrieves subtitle tracks for [contentId].
  Future<List<SubtitleTrack>> execute(String contentId) {
    return _repository.getSubtitles(contentId);
  }
}
