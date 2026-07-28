import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Material 3 Playback Controls bar.
class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final bool isPipActive;
  final bool isFullscreen;
  final PlaybackSpeed speed;
  final VoidCallback onPlayPause;
  final VoidCallback onTogglePip;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<PlaybackSpeed>? onSpeedChanged;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.isPipActive,
    required this.isFullscreen,
    required this.speed,
    required this.onPlayPause,
    required this.onTogglePip,
    required this.onToggleFullscreen,
    this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: onPlayPause,
          icon:
              Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          iconSize: 32,
          color: colorScheme.primary,
        ),
        IconButton(
          onPressed: onTogglePip,
          icon: Icon(isPipActive
              ? Icons.picture_in_picture_alt_rounded
              : Icons.picture_in_picture_rounded),
          color:
              isPipActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        IconButton(
          onPressed: onToggleFullscreen,
          icon: Icon(isFullscreen
              ? Icons.fullscreen_exit_rounded
              : Icons.fullscreen_rounded),
          color:
              isFullscreen ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        Chip(
          label: Text(speed.label),
          avatar: const Icon(Icons.speed_rounded, size: 16),
        ),
      ],
    );
  }
}
