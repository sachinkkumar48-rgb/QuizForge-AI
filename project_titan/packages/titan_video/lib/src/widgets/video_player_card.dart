import 'package:flutter/material.dart';
import '../models/video_models.dart';
import 'playback_controls.dart';
import 'playback_timeline.dart';

/// Responsive Material 3 Video Player Card component.
class VideoPlayerCard extends StatelessWidget {
  final VideoContent video;
  final PlaybackState playbackState;
  final VoidCallback onPlayPause;
  final ValueChanged<int> onSeek;
  final VoidCallback onTogglePip;
  final VoidCallback onToggleFullscreen;

  const VideoPlayerCard({
    super.key,
    required this.video,
    required this.playbackState,
    required this.onPlayPause,
    required this.onSeek,
    required this.onTogglePip,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Player Screen Canvas Overlay
          AspectRatio(
            aspectRatio: video.videoMetadata.aspectRatio > 0
                ? video.videoMetadata.aspectRatio
                : 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          playbackState.isPlaying
                              ? Icons.play_circle_filled_rounded
                              : Icons.pause_circle_filled_rounded,
                          size: 64,
                          color: colorScheme.primary.withAlpha(200),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtitle Overlay
                if (playbackState.positionSeconds > 0 &&
                    video.transcript.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(178),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        video.transcript.first.text,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Controls & Timeline Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                PlaybackTimeline(
                  positionSeconds: playbackState.positionSeconds,
                  durationSeconds: playbackState.durationSeconds > 0
                      ? playbackState.durationSeconds
                      : video.videoMetadata.durationSeconds,
                  onSeek: onSeek,
                ),
                PlaybackControls(
                  isPlaying: playbackState.isPlaying,
                  isPipActive: playbackState.isPipActive,
                  isFullscreen: playbackState.isFullscreen,
                  speed: playbackState.speed,
                  onPlayPause: onPlayPause,
                  onTogglePip: onTogglePip,
                  onToggleFullscreen: onToggleFullscreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
