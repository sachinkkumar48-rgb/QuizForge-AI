import '../engine/video_playback_engine.dart';
import '../models/video_models.dart';

/// Clean Architecture Use Case for seeking playback position.
class SeekVideoUseCase {
  final VideoPlaybackEngine _playbackEngine;

  const SeekVideoUseCase(this._playbackEngine);

  /// Seeks playback to [positionSeconds].
  PlaybackState execute(int positionSeconds) {
    _playbackEngine.seekTo(positionSeconds);
    return _playbackEngine.currentState;
  }
}
