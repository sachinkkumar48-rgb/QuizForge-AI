import '../engine/video_playback_engine.dart';
import '../models/video_models.dart';

/// Clean Architecture Use Case for resuming video playback.
class ResumeVideoUseCase {
  final VideoPlaybackEngine _playbackEngine;

  const ResumeVideoUseCase(this._playbackEngine);

  /// Resumes playback.
  PlaybackState execute() {
    _playbackEngine.resume();
    return _playbackEngine.currentState;
  }
}
