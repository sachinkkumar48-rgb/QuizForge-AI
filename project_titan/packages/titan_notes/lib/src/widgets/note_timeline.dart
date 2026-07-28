import 'package:flutter/material.dart';
import '../models/smart_note.dart';

/// Material 3 Note Timeline component.
class NoteTimeline extends StatelessWidget {
  final List<SmartNote> notes;
  final ValueChanged<SmartNote> onNoteTap;

  const NoteTimeline({
    super.key,
    required this.notes,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      itemCount: notes.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final note = notes[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.note_alt_rounded,
                      size: 16, color: colorScheme.primary),
                ),
                if (index < notes.length - 1)
                  Container(
                    width: 2,
                    height: 48,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(note.title, style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${note.updatedAt.day}/${note.updatedAt.month}',
                    style: theme.textTheme.labelSmall,
                  ),
                  onTap: () => onNoteTap(note),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
