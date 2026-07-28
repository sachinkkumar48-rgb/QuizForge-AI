import 'package:flutter/material.dart';
import '../models/video_chapter.dart';

/// Material 3 Chapter List widget.
class ChapterList extends StatelessWidget {
  final List<VideoChapter> chapters;
  final int currentTimestampSeconds;
  final ValueChanged<VideoChapter> onChapterTap;

  const ChapterList({
    super.key,
    required this.chapters,
    required this.currentTimestampSeconds,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      itemCount: chapters.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final ch = chapters[index];
        final isActive = currentTimestampSeconds >= ch.startSeconds &&
            currentTimestampSeconds <= ch.endSeconds;

        return Card(
          elevation: isActive ? 2 : 0,
          color:
              isActive ? colorScheme.secondaryContainer : colorScheme.surface,
          child: ListTile(
            leading: Icon(
              isActive
                  ? Icons.play_circle_fill_rounded
                  : Icons.label_important_outline_rounded,
              color:
                  isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: Text(ch.title, style: theme.textTheme.titleSmall),
            subtitle: Text('${ch.startSeconds}s - ${ch.endSeconds}s',
                style: theme.textTheme.labelSmall),
            onTap: () => onChapterTap(ch),
          ),
        );
      },
    );
  }
}
