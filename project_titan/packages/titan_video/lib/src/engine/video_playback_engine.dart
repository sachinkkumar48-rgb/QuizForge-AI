import 'dart:async';
import '../models/enums.dart';
import '../models/playback_state.dart';
import '../models/video_chapter.dart';

/// Pure Dart video playback orchestrator managing playback state, seeking,
/// speed, PiP mode, fullscreen, and background playback state transitions.
class VideoPlaybackEngine {
  PlaybackState _currentState;
  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  List<VideoChapter> _chapters;

  VideoPlaybackEngine({
    PlaybackState initialState = const PlaybackState(),
    List<VideoChapter>? chapters,
  })  : _currentState = initialState,
        _chapters = List<VideoChapter>.unmodifiable(chapters ?? const []);

  /// Stream of playback state changes.
  Stream<PlaybackState> get stateStream => _stateController.stream;

  /// Current snapshot of playback state.
  PlaybackState get currentState => _currentState;

  /// Current list of video chapters.
  List<VideoChapter> get chapters => _chapters;

  void setChapters(List<VideoChapter> chapters) {
    _chapters = List<VideoChapter>.unmodifiable(chapters);
  }

  void _emit(PlaybackState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  /// Starts or resumes playback.
  void play({int? durationSeconds}) {
    _emit(
      _currentState.copyWith(
        isPlaying: true,
        isBuffering: false,
        durationSeconds: durationSeconds ?? _currentState.durationSeconds,
      ),
    );
  }

  /// Pauses playback.
  void pause() {
    _emit(_currentState.copyWith(isPlaying: false));
  }

  /// Resumes playback if paused.
  void resume() {
    play();
  }

  /// Seeks to specified position in seconds.
  void seekTo(int positionSeconds) {
    final clamped = positionSeconds.clamp(
        0,
        _currentState.durationSeconds > 0
            ? _currentState.durationSeconds
            : positionSeconds);
    _emit(_currentState.copyWith(positionSeconds: clamped));
  }

  /// Changes playback speed multiplier.
  void setSpeed(PlaybackSpeed speed) {
    _emit(_currentState.copyWith(speed: speed));
  }

  /// Changes video resolution quality.
  void setQuality(VideoQuality quality) {
    _emit(_currentState.copyWith(quality: quality));
  }

  /// Toggles mute state.
  void toggleMute() {
    _emit(_currentState.copyWith(isMuted: !_currentState.isMuted));
  }

  /// Sets audio volume (0.0 - 1.0).
  void setVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    _emit(_currentState.copyWith(volume: clamped, isMuted: clamped == 0.0));
  }

  /// Toggles Picture-in-Picture (PiP) mode.
  void setPipActive(bool active) {
    _emit(_currentState.copyWith(isPipActive: active));
  }

  /// Toggles Fullscreen display state.
  void setFullscreen(bool active) {
    _emit(_currentState.copyWith(isFullscreen: active));
  }

  /// Jump to specific chapter by index.
  void jumpToChapter(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= _chapters.length) return;
    final targetChapter = _chapters[chapterIndex];
    seekTo(targetChapter.startSeconds);
  }

  /// Advances playback position by delta seconds (simulating tick).
  void tickPosition(int deltaSeconds) {
    if (!_currentState.isPlaying || _currentState.isBuffering) return;
    final nextPos = _currentState.positionSeconds +
        (deltaSeconds * _currentState.speed.multiplier).round();
    seekTo(nextPos);
  }

  /// Disposes stream controller.
  void dispose() {
    _stateController.close();
  }
}
