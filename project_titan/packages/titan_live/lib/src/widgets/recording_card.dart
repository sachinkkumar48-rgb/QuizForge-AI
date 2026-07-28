import 'package:flutter/material.dart';
import '../models/live_models.dart';

/// Card displaying recorded class metadata and play trigger.
class RecordingCard extends StatelessWidget {
  final Recording recording;
  final String title;
  final VoidCallback? onPlayTap;

  const RecordingCard({
    super.key,
    required this.recording,
    required this.title,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationMins = (recording.durationSeconds / 60).round();

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.play_arrow),
        ),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(
            'Duration: $durationMins mins • Status: ${recording.status.name}'),
        trailing: FilledButton(
          onPressed: onPlayTap,
          child: const Text('Play'),
        ),
      ),
    );
  }
}
