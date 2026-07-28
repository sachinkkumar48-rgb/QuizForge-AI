import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing real-time playback state of a video stream.
@immutable
class PlaybackState {
  final int positionSeconds;
  final int durationSeconds;
  final bool isPlaying;
  final bool isBuffering;
  final PlaybackSpeed speed;
  final VideoQuality quality;
  final bool isMuted;
  final double volume;
  final bool isPipActive;
  final bool isFullscreen;

  const PlaybackState({
    this.positionSeconds = 0,
    this.durationSeconds = 0,
    this.isPlaying = false,
    this.isBuffering = false,
    this.speed = PlaybackSpeed.speed1_0x,
    this.quality = VideoQuality.auto,
    this.isMuted = false,
    this.volume = 1.0,
    this.isPipActive = false,
    this.isFullscreen = false,
  });

  double get progressPercentage {
    if (durationSeconds <= 0) return 0.0;
    return (positionSeconds / durationSeconds * 100.0).clamp(0.0, 100.0);
  }

  PlaybackState copyWith({
    int? positionSeconds,
    int? durationSeconds,
    bool? isPlaying,
    bool? isBuffering,
    PlaybackSpeed? speed,
    VideoQuality? quality,
    bool? isMuted,
    double? volume,
    bool? isPipActive,
    bool? isFullscreen,
  }) {
    return PlaybackState(
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      speed: speed ?? this.speed,
      quality: quality ?? this.quality,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      isPipActive: isPipActive ?? this.isPipActive,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }

  Map<String, dynamic> toJson() => {
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'isPlaying': isPlaying,
        'isBuffering': isBuffering,
        'speed': speed.name,
        'quality': quality.name,
        'isMuted': isMuted,
        'volume': volume,
        'isPipActive': isPipActive,
        'isFullscreen': isFullscreen,
      };

  factory PlaybackState.fromJson(Map<String, dynamic> json) => PlaybackState(
        positionSeconds: json['positionSeconds'] as int? ?? 0,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        isPlaying: json['isPlaying'] as bool? ?? false,
        isBuffering: json['isBuffering'] as bool? ?? false,
        speed: PlaybackSpeed.values.firstWhere(
          (e) => e.name == json['speed'],
          orElse: () => PlaybackSpeed.speed1_0x,
        ),
        quality: VideoQuality.values.firstWhere(
          (e) => e.name == json['quality'],
          orElse: () => VideoQuality.auto,
        ),
        isMuted: json['isMuted'] as bool? ?? false,
        volume: (json['volume'] as num? ?? 1.0).toDouble(),
        isPipActive: json['isPipActive'] as bool? ?? false,
        isFullscreen: json['isFullscreen'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackState &&
          runtimeType == other.runtimeType &&
          positionSeconds == other.positionSeconds &&
          durationSeconds == other.durationSeconds &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          speed == other.speed &&
          quality == other.quality &&
          isMuted == other.isMuted &&
          volume == other.volume &&
          isPipActive == other.isPipActive &&
          isFullscreen == other.isFullscreen;

  @override
  int get hashCode => Object.hash(
        positionSeconds,
        durationSeconds,
        isPlaying,
        isBuffering,
        speed,
        quality,
        isMuted,
        volume,
        isPipActive,
        isFullscreen,
      );
}
