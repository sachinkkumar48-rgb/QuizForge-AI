import 'package:flutter/material.dart';
import '../models/smart_note.dart';
import 'note_tag_chip.dart';

/// Material 3 Smart Note Card widget.
class SmartNoteCard extends StatelessWidget {
  final SmartNote note;
  final VoidCallback onTap;
  final VoidCallback? onPinTap;
  final VoidCallback? onDeleteTap;

  const SmartNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onPinTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: note.isPinned ? 3 : 1,
      color: note.isPinned
          ? colorScheme.primaryContainer.withAlpha(50)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onPinTap != null)
                    IconButton(
                      icon: Icon(
                        note.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        color: note.isPinned
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: onPinTap,
                    ),
                  if (onDeleteTap != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: onDeleteTap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (note.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      note.tags.map((tag) => NoteTagChip(tag: tag)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
