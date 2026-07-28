import '../models/video_models.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for retrieving active continue watching items.
class ContinueWatchingUseCase {
  final VideoRepository _repository;

  const ContinueWatchingUseCase(this._repository);

  /// Retrieves list of in-progress videos for [userId].
  Future<List<ContinueWatching>> execute(String userId) {
    return _repository.getContinueWatching(userId);
  }
}
