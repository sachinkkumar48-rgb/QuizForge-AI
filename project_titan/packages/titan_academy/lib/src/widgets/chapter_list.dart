import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/lesson.dart';
import 'lesson_card.dart';

/// Material 3 accordion widget rendering list of chapters with expandable nested lessons.
class ChapterList extends StatelessWidget {
  final List<Chapter> chapters;
  final String? activeLessonId;
  final void Function(Lesson lesson)? onLessonTap;

  const ChapterList({
    super.key,
    required this.chapters,
    this.activeLessonId,
    this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No chapters available.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final completedCount =
            chapter.lessons.where((l) => l.isCompleted).length;
        final totalCount = chapter.lessons.length;

        return Card(
          elevation: 0.0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: ExpansionTile(
            shape: const Border(),
            leading: CircleAvatar(
              radius: 14.0,
              backgroundColor: chapter.isCompleted
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: chapter.isCompleted
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              chapter.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '$completedCount/$totalCount Lessons • ${chapter.durationMinutes} mins',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
            children: chapter.lessons.map((lesson) {
              final isCurrent = lesson.id == activeLessonId;
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: LessonCard(
                  lesson: lesson,
                  isCurrent: isCurrent,
                  onTap: () => onLessonTap?.call(lesson),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
