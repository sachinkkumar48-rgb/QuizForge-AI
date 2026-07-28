import '../models/video_models.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for saving video playback position.
class SavePlaybackUseCase {
  final VideoRepository _repository;

  const SavePlaybackUseCase(this._repository);

  /// Saves position for [userId] on [contentId].
  Future<PlaybackState> execute({
    required String userId,
    required String contentId,
    required int positionSeconds,
    required int durationSeconds,
  }) {
    return _repository.savePlaybackPosition(
      userId: userId,
      contentId: contentId,
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
    );
  }
}
