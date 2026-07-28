import 'package:flutter/material.dart';
import '../models/subtitle_track.dart';

/// Material 3 Subtitle Track Selector Panel.
class SubtitlePanel extends StatelessWidget {
  final List<SubtitleTrack> tracks;
  final SubtitleTrack? selectedTrack;
  final ValueChanged<SubtitleTrack?> onSelectTrack;

  const SubtitlePanel({
    super.key,
    required this.tracks,
    this.selectedTrack,
    required this.onSelectTrack,
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
          child:
              Text('Subtitles & Captions', style: theme.textTheme.titleMedium),
        ),
        ListTile(
          leading: Icon(
            selectedTrack == null
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selectedTrack == null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          title: const Text('Off'),
          onTap: () => onSelectTrack(null),
        ),
        ...tracks.map(
          (track) => ListTile(
            leading: Icon(
              selectedTrack == track
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selectedTrack == track
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            title: Text(
                '${track.languageName} (${track.languageCode.toUpperCase()})'),
            onTap: () => onSelectTrack(track),
          ),
        ),
      ],
    );
  }
}
