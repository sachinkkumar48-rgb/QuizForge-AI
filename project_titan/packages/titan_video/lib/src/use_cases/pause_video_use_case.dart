import '../engine/video_playback_engine.dart';
import '../models/video_models.dart';

/// Clean Architecture Use Case for pausing video playback.
class PauseVideoUseCase {
  final VideoPlaybackEngine _playbackEngine;

  const PauseVideoUseCase(this._playbackEngine);

  /// Pauses playback and returns current state.
  PlaybackState execute() {
    _playbackEngine.pause();
    return _playbackEngine.currentState;
  }
}
