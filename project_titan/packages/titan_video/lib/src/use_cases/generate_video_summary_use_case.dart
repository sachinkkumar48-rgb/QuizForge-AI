import '../integration/video_engine_integrator.dart';
import '../repository/video_repository.dart';

/// Clean Architecture Use Case for generating an AI summary of a video lesson.
class GenerateVideoSummaryUseCase {
  final VideoRepository _repository;
  final VideoEngineIntegrator _integrator;

  const GenerateVideoSummaryUseCase(
    this._repository, {
    VideoEngineIntegrator integrator = const VideoEngineIntegrator(),
  }) : _integrator = integrator;

  /// Generates AI summary for [contentId].
  Future<String> execute(String contentId) async {
    final video = await _repository.getVideoContentById(contentId);
    if (video == null) {
      return 'Video content not found.';
    }
    return _integrator.generateVideoSummary(video);
  }
}
