import '../models/video_models.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for fetching video transcript segments.
class GetTranscriptUseCase {
  final VideoRepository _repository;

  const GetTranscriptUseCase(this._repository);

  /// Retrieves transcript segments for [contentId].
  Future<List<TranscriptSegment>> execute(String contentId) {
    return _repository.getTranscript(contentId);
  }
}
