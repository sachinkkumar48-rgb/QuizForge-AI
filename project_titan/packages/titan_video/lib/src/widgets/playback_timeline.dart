import 'package:flutter/material.dart';

/// Material 3 Playback Timeline bar.
class PlaybackTimeline extends StatelessWidget {
  final int positionSeconds;
  final int durationSeconds;
  final ValueChanged<int> onSeek;

  const PlaybackTimeline({
    super.key,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.onSeek,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = durationSeconds > 0 ? durationSeconds.toDouble() : 1.0;
    final currentVal = positionSeconds.clamp(0, durationSeconds).toDouble();

    return Row(
      children: [
        Text(_formatDuration(positionSeconds),
            style: theme.textTheme.labelMedium),
        Expanded(
          child: Slider(
            value: currentVal,
            min: 0,
            max: maxVal,
            onChanged: (val) => onSeek(val.toInt()),
          ),
        ),
        Text(_formatDuration(durationSeconds),
            style: theme.textTheme.labelMedium),
      ],
    );
  }
}
