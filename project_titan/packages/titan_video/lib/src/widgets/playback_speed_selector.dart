import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Material 3 Playback Speed Selector Modal / Dialog.
class PlaybackSpeedSelector extends StatelessWidget {
  final PlaybackSpeed currentSpeed;
  final ValueChanged<PlaybackSpeed> onSpeedSelected;

  const PlaybackSpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Playback Speed', style: theme.textTheme.titleMedium),
        ),
        ...PlaybackSpeed.values.map(
          (speed) => ListTile(
            leading: Icon(
              currentSpeed == speed
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: currentSpeed == speed
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            title: Text(speed.label),
            onTap: () => onSpeedSelected(speed),
          ),
        ),
      ],
    );
  }
}
