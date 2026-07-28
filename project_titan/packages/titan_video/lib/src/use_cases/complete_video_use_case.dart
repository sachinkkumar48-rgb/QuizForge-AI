import '../integration/video_engine_integrator.dart';
import '../models/video_models.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for marking video as 100% completed.
class CompleteVideoUseCase {
  final VideoRepository _repository;
  final VideoEngineIntegrator _integrator;

  const CompleteVideoUseCase(
    this._repository, {
    VideoEngineIntegrator integrator = const VideoEngineIntegrator(),
  }) : _integrator = integrator;

  /// Marks [contentId] as completed for [userId] and triggers profile & analytics updates.
  Future<VideoContent?> execute({
    required String userId,
    required String contentId,
  }) async {
    final video = await _repository.getVideoContentById(contentId);
    if (video == null) return null;

    final duration = video.videoMetadata.durationSeconds;
    await _repository.savePlaybackPosition(
      userId: userId,
      contentId: contentId,
      positionSeconds: duration,
      durationSeconds: duration,
    );

    await _integrator.syncWatchProgressToProfile(
      userId: userId,
      video: video,
      watchedSeconds: duration,
    );

    return video;
  }
}
