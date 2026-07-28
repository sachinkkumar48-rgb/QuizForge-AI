import 'package:flutter/material.dart';
import '../models/lesson.dart';

/// Material 3 card widget displaying lesson details, type badge, duration, and status.
class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isCurrent;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final leadingIcon = lesson.isCompleted
        ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
        : isCurrent
            ? Icon(Icons.play_circle_fill_rounded, color: colorScheme.secondary)
            : Icon(Icons.radio_button_unchecked_rounded,
                color: colorScheme.onSurfaceVariant);

    return Card(
      elevation: 0.0,
      color: isCurrent
          ? colorScheme.secondaryContainer.withValues(alpha: 0.4)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isCurrent ? colorScheme.secondary : colorScheme.outlineVariant,
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        onTap: onTap,
        leading: leadingIcon,
        title: Text(
          lesson.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            decoration: lesson.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(_getTypeIcon(lesson.type),
                size: 14.0, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4.0),
            Text(
              '${lesson.durationMinutes} mins • ${lesson.type.toUpperCase()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14.0,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam_outlined;
      case 'article':
        return Icons.article_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'interactive':
        return Icons.touch_app_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }
}
