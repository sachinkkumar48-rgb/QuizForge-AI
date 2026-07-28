import 'package:flutter/material.dart';
import '../models/video_note.dart';

/// Material 3 Video Notes Panel displaying timestamped user and AI notes.
class VideoNotesPanel extends StatelessWidget {
  final List<VideoNote> notes;
  final ValueChanged<VideoNote> onNoteTap;
  final VoidCallback onAddNote;

  const VideoNotesPanel({
    super.key,
    required this.notes,
    required this.onNoteTap,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Video Notes (${notes.length})',
                  style: theme.textTheme.titleSmall),
              IconButton.filledTonal(
                onPressed: onAddNote,
                icon: const Icon(Icons.add_comment_rounded),
                tooltip: 'Add Note at current time',
              ),
            ],
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Text('No notes created yet.',
                      style: theme.textTheme.bodyMedium))
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          child: Text('${note.timestampSeconds}s',
                              style: theme.textTheme.labelSmall),
                        ),
                        title:
                            Text(note.text, style: theme.textTheme.bodyMedium),
                        onTap: () => onNoteTap(note),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
