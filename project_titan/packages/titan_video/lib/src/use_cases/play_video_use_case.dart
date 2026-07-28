import '../engine/video_playback_engine.dart';
import '../models/video_models.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for starting video playback.
class PlayVideoUseCase {
  final VideoRepository _repository;
  final VideoPlaybackEngine _playbackEngine;

  const PlayVideoUseCase(this._repository, this._playbackEngine);

  /// Initiates playback for [contentId].
  Future<VideoContent?> execute(String contentId) async {
    final video = await _repository.getVideoContentById(contentId);
    if (video != null) {
      _playbackEngine.setChapters(video.chapters);
      _playbackEngine.play(
          durationSeconds: video.videoMetadata.durationSeconds);
    }
    return video;
  }
}
